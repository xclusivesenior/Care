<#
.SYNOPSIS
    Works out whether Claude Desktop is still installed and, if it is,
    puts the desktop shortcut back.

.DESCRIPTION
    After a 0x80073D05 failure - or after running
    Repair-ClaudeDesktopInstall.ps1, which removes the package by design -
    the desktop icon is gone. That can mean either "only the shortcut was
    lost" or "the app itself is no longer installed", and the fixes differ.
    This script tells you which, and repairs the first case.

    No elevation required.

.EXAMPLE
    .\Restore-ClaudeDesktopShortcut.ps1
    .\Restore-ClaudeDesktopShortcut.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string] $ShortcutName = 'Claude.lnk'
)

$ErrorActionPreference = 'Stop'

function Write-Step { param([string] $Message) Write-Host "==> $Message" -ForegroundColor Cyan }
function Write-Note { param([string] $Message) Write-Host "    $Message" -ForegroundColor DarkGray }

# --- 1. Is the desktop even showing icons? ----------------------------------
# A toggled-off "Show desktop icons" hides every shortcut and looks exactly
# like an uninstall. Cheap to check, so check it first.
$explorerKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
$hideIcons = (Get-ItemProperty -Path $explorerKey -Name 'HideIcons' -ErrorAction SilentlyContinue).HideIcons
if ($hideIcons -eq 1) {
    Write-Host '! Desktop icons are currently hidden for your account.' -ForegroundColor Yellow
    Write-Host '  Right-click the desktop -> View -> Show desktop icons.' -ForegroundColor Yellow
    Write-Host '  Claude may not be missing at all.' -ForegroundColor Yellow
    Write-Host ''
}

# --- 2. Locate an installed claude.exe --------------------------------------
Write-Step 'Looking for an installed Claude Desktop'

$exe = $null

# a) The direct desktop installer (Squirrel layout: versioned app-* folders).
$installRoot = Join-Path $env:LOCALAPPDATA 'AnthropicClaude'
if (Test-Path -LiteralPath $installRoot) {
    $exe = Get-ChildItem -LiteralPath $installRoot -Recurse -Filter 'claude.exe' -ErrorAction SilentlyContinue |
           Sort-Object LastWriteTime -Descending |
           Select-Object -First 1 -ExpandProperty FullName
}

# b) The MSIX/Store package, which is launched by app alias rather than path.
$pkg = Get-AppxPackage -Name '*Claude*' -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $exe -and -not $pkg) {
    Write-Host ''
    Write-Host 'Claude Desktop is NOT installed - the shortcut is not the problem.' -ForegroundColor Yellow
    Write-Host 'The failed install removed it. Reinstall from https://claude.ai/download' -ForegroundColor Yellow
    Write-Host 'and run Claude-Setup-x64.exe (this path avoids 0x80073D05 entirely).'   -ForegroundColor Yellow
    return
}

# --- 3. Recreate the shortcut -----------------------------------------------
$desktop  = [Environment]::GetFolderPath('Desktop')
$linkPath = Join-Path $desktop $ShortcutName

if ($exe) {
    Write-Note "Found $exe"
    if ($PSCmdlet.ShouldProcess($linkPath, 'Create desktop shortcut')) {
        $shell    = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($linkPath)
        $shortcut.TargetPath       = $exe
        $shortcut.WorkingDirectory = Split-Path -Parent $exe
        $shortcut.Description      = 'Claude Desktop'
        $shortcut.Save()
        Write-Host ''
        Write-Host "Shortcut restored: $linkPath" -ForegroundColor Green
    }
} else {
    # Store packages have no stable .exe path to point a .lnk at; the Start
    # menu entry is generated from the manifest instead.
    Write-Note "Found Store package $($pkg.PackageFullName)"
    Write-Host ''
    Write-Host 'This is the Store build - launch it from the Start menu (search "Claude"),' -ForegroundColor Green
    Write-Host 'then drag that Start menu entry onto your desktop to make an icon.'         -ForegroundColor Green
}
