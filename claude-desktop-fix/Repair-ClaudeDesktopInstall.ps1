<#
.SYNOPSIS
    Clears the stale app-data store that causes Claude Desktop to fail
    installing with 0x80073D05.

.DESCRIPTION
    0x80073D05 is ERROR_DELETING_EXISTING_APPLICATIONDATA_STORE_FAILED:
    Windows cannot delete the previous package's app-data folder under
    %LOCALAPPDATA%\Packages, so deployment aborts. This script stops the
    processes holding it, removes the package, force-deletes the orphaned
    folder (taking ownership if needed), and resets the AppX/Store stack.

.PARAMETER PackageName
    Wildcard matched against Get-AppxPackage -Name. Defaults to *Claude*.

.EXAMPLE
    .\Repair-ClaudeDesktopInstall.ps1 -WhatIf
    .\Repair-ClaudeDesktopInstall.ps1
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string] $PackageName = '*Claude*'
)

$ErrorActionPreference = 'Stop'

function Write-Step { param([string] $Message) Write-Host "==> $Message" -ForegroundColor Cyan }
function Write-Note { param([string] $Message) Write-Host "    $Message" -ForegroundColor DarkGray }
function Write-Warn { param([string] $Message) Write-Host "  ! $Message" -ForegroundColor Yellow }

# --- 0. Must be elevated -----------------------------------------------------
$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run this script from an elevated PowerShell (Run as Administrator).'
}

# --- 0b. Log everything, so a failed run can be diagnosed from one file -----
$logPath = Join-Path $env:TEMP ('ClaudeRepair-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.log')
try { Start-Transcript -Path $logPath -Force | Out-Null; $transcript = $true }
catch { $transcript = $false }

# --- 0c. A pending reboot is the usual reason this error repeats ------------
# Windows defers locked-file deletes to the next boot. If a rename is already
# queued, deleting the app-data folder cannot stick and the very next install
# fails with the identical code - which is exactly what "I reinstalled over
# and over, same error" looks like from the outside.
$pendingReasons = @()

$pfro = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' `
         -Name 'PendingFileRenameOperations' -ErrorAction SilentlyContinue).PendingFileRenameOperations
if ($pfro) { $pendingReasons += 'files are queued for rename/delete at next boot' }

$rebootKeys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
)
foreach ($key in $rebootKeys) {
    if (Test-Path -LiteralPath $key) { $pendingReasons += "servicing flag: $(Split-Path $key -Leaf)" }
}

if ($pendingReasons.Count -gt 0) {
    Write-Host ''
    Write-Host '!! A REBOOT IS ALREADY PENDING on this machine.' -ForegroundColor Yellow
    foreach ($r in $pendingReasons) { Write-Host "   - $r" -ForegroundColor Yellow }
    Write-Host ''
    Write-Host '   This is the most common reason the same install fails repeatedly:'  -ForegroundColor Yellow
    Write-Host '   Windows cannot finish deleting the old app data until it reboots,'  -ForegroundColor Yellow
    Write-Host '   so every retry hits 0x80073D05 again.'                              -ForegroundColor Yellow
    Write-Host ''
    Write-Host '   REBOOT NOW, then run this script again before installing.'          -ForegroundColor Yellow
    Write-Host ''
    $answer = Read-Host '   Continue anyway? (y/N)'
    if ($answer -notmatch '^(y|yes)$') {
        Write-Host 'Stopped. Reboot, then re-run this script.' -ForegroundColor Cyan
        if ($transcript) { Stop-Transcript | Out-Null }
        return
    }
} else {
    Write-Host '==> No pending reboot - safe to repair now.' -ForegroundColor Cyan
}

# --- 1. Stop anything holding the data store open ---------------------------
Write-Step 'Stopping running Claude processes'
$procs = Get-Process -Name 'claude*' -ErrorAction SilentlyContinue
if ($procs) {
    foreach ($p in $procs) {
        if ($PSCmdlet.ShouldProcess("$($p.ProcessName) (PID $($p.Id))", 'Stop-Process')) {
            Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Note "Stopped $($procs.Count) process(es)."
} else {
    Write-Note 'None running.'
}

# --- 2. Remove the package (this user, then all users) ----------------------
Write-Step "Removing installed packages matching '$PackageName'"

# Capture the family names BEFORE removal - we need them to find the folders.
$familyNames = @(
    Get-AppxPackage -Name $PackageName -AllUsers -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty PackageFamilyName -Unique
)

$installed = Get-AppxPackage -Name $PackageName -ErrorAction SilentlyContinue
foreach ($pkg in $installed) {
    if ($PSCmdlet.ShouldProcess($pkg.PackageFullName, 'Remove-AppxPackage')) {
        try { Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop }
        catch { Write-Warn "Remove-AppxPackage failed: $($_.Exception.Message)" }
    }
}

foreach ($pkg in (Get-AppxPackage -Name $PackageName -AllUsers -ErrorAction SilentlyContinue)) {
    if ($PSCmdlet.ShouldProcess($pkg.PackageFullName, 'Remove-AppxPackage -AllUsers')) {
        try { Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop }
        catch { Write-Warn "Remove-AppxPackage -AllUsers failed: $($_.Exception.Message)" }
    }
}

foreach ($prov in (Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
                   Where-Object { $_.DisplayName -like $PackageName })) {
    if ($PSCmdlet.ShouldProcess($prov.PackageName, 'Remove-AppxProvisionedPackage')) {
        try { Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction Stop | Out-Null }
        catch { Write-Warn "Remove-AppxProvisionedPackage failed: $($_.Exception.Message)" }
    }
}

if (-not $familyNames) { Write-Note 'No installed package found (expected if a prior attempt half-removed it).' }

# --- 3. Delete the orphaned app-data folders (the actual 0x80073D05 cause) ---
Write-Step 'Deleting orphaned app-data folders'

$packagesRoot = Join-Path $env:LOCALAPPDATA 'Packages'
$targets = New-Object System.Collections.Generic.List[string]

foreach ($family in $familyNames) {
    $path = Join-Path $packagesRoot $family
    if (Test-Path -LiteralPath $path) { $targets.Add($path) }
}

# Also catch folders left behind by a package that is no longer registered.
if (Test-Path -LiteralPath $packagesRoot) {
    Get-ChildItem -LiteralPath $packagesRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like $PackageName } |
        ForEach-Object { if (-not $targets.Contains($_.FullName)) { $targets.Add($_.FullName) } }
}

if ($targets.Count -eq 0) {
    Write-Note 'Nothing left behind under %LOCALAPPDATA%\Packages.'
}

foreach ($path in $targets) {
    if (-not $PSCmdlet.ShouldProcess($path, 'Delete app-data folder')) { continue }

    Write-Note "Removing $path"
    try {
        Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction Stop
    } catch {
        # Permissions are the usual blocker - take ownership and retry once.
        Write-Warn 'Direct delete failed; taking ownership and retrying.'
        & takeown.exe /F $path /R /D Y  | Out-Null
        & icacls.exe  $path /grant "$($identity.Name):(F)" /T /C /Q | Out-Null
        try {
            Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction Stop
        } catch {
            Write-Warn "Still could not delete $path : $($_.Exception.Message)"
            Write-Warn 'Reboot and re-run this script before installing again.'
        }
    }
}

# --- 4. Clear the Store download cache --------------------------------------
Write-Step 'Clearing the Microsoft Store cache (wsreset)'
if ($PSCmdlet.ShouldProcess('Microsoft Store cache', 'wsreset.exe')) {
    $wsreset = Start-Process -FilePath 'wsreset.exe' -PassThru -ErrorAction SilentlyContinue
    if ($wsreset) { $wsreset.WaitForExit(60000) | Out-Null }
}

# --- 5. Re-register the AppX / Store stack ----------------------------------
Write-Step 'Re-registering the Store and AppX deployment stack'
if ($PSCmdlet.ShouldProcess('AppX deployment stack', 'Re-register')) {
    foreach ($name in @('Microsoft.WindowsStore', 'Microsoft.DesktopAppInstaller')) {
        $pkg = Get-AppxPackage -Name $name -ErrorAction SilentlyContinue
        if (-not $pkg) { continue }
        $manifest = Join-Path $pkg.InstallLocation 'AppxManifest.xml'
        if (Test-Path -LiteralPath $manifest) {
            try { Add-AppxPackage -DisableDevelopmentMode -Register $manifest -ErrorAction Stop }
            catch { Write-Warn "Could not re-register $name : $($_.Exception.Message)" }
        }
    }
}

# --- 6. Verify the repair actually took -------------------------------------
# The whole point is that the blocking folder is gone. Say so plainly rather
# than reporting "Done" and letting the next install discover otherwise.
Write-Step 'Verifying'

$remaining = @()
foreach ($path in $targets) {
    if (Test-Path -LiteralPath $path) { $remaining += $path }
}
$stillInstalled = @(Get-AppxPackage -Name $PackageName -ErrorAction SilentlyContinue)

Write-Host ''
if ($remaining.Count -eq 0 -and $stillInstalled.Count -eq 0) {
    Write-Host 'PASS - the blocking app-data folder is gone.' -ForegroundColor Green
    Write-Host ''
    Write-Host 'Next: reboot, then install Claude Desktop once.' -ForegroundColor Green
    Write-Host 'The direct installer at https://claude.ai/download avoids this error entirely.' -ForegroundColor Green
} else {
    Write-Host 'INCOMPLETE - something is still holding on:' -ForegroundColor Yellow
    foreach ($r in $remaining)      { Write-Host "   folder still present: $r"          -ForegroundColor Yellow }
    foreach ($p in $stillInstalled) { Write-Host "   package still registered: $($p.Name)" -ForegroundColor Yellow }
    Write-Host ''
    Write-Host 'This almost always means a file is locked until reboot.'      -ForegroundColor Yellow
    Write-Host 'REBOOT, then run this script once more. It should report PASS.' -ForegroundColor Yellow
}

Write-Host ''
Write-Host 'If the next install still fails, run this and send the output:' -ForegroundColor Cyan
Write-Host '  Get-AppxLog -All | Select-Object -First 40 | Format-List'     -ForegroundColor Cyan

if ($transcript) {
    Stop-Transcript | Out-Null
    Write-Host ''
    Write-Host "Full log of this run: $logPath" -ForegroundColor DarkGray
}
