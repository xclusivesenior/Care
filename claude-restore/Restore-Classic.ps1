<#
.SYNOPSIS
  Restore Claude Desktop (and the claude.ai browser state) to a clean working setup.

.DESCRIPTION
  Use this when Claude Desktop is broken, half-installed, or stuck after a failed
  update - including the 0x80073D05 loop.

  It does NOT touch anything outside Claude's own folders. Your settings are
  BACKED UP to the Desktop before removal, never silently deleted.

  Browser data is deliberately NOT scripted. Clearing a browser profile from a
  script is how people lose every saved login on the machine. This opens the
  exact per-site page instead, so only claude.ai is reset.
#>
[CmdletBinding()]
param(
  [switch]$SkipPrompt,   # run without the confirmation gate
  [switch]$KeepSettings  # back up settings but put them back after the clean-out
)

$ErrorActionPreference = 'Stop'
$stamp   = Get-Date -Format 'yyyyMMdd-HHmmss'
$logPath = Join-Path $env:TEMP "ClaudeRestore-$stamp.log"
try { Start-Transcript -Path $logPath -Force | Out-Null } catch {}

function Say  ($m,$c='Gray'){ Write-Host $m -ForegroundColor $c }
function Head ($m){ Write-Host ""; Write-Host "== $m" -ForegroundColor Cyan }
function Ok   ($m){ Write-Host "   [ok]   $m" -ForegroundColor Green }
function Warn ($m){ Write-Host "   [warn] $m" -ForegroundColor Yellow }
function Bad  ($m){ Write-Host "   [fail] $m" -ForegroundColor Red }

Write-Host ""
Write-Host "  Restore Claude to a clean install" -ForegroundColor White
Write-Host "  ---------------------------------" -ForegroundColor DarkGray

# ---- 1. administrator ---------------------------------------------------
$admin = ([Security.Principal.WindowsPrincipal] `
          [Security.Principal.WindowsIdentity]::GetCurrent()
         ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
  Bad "Not running as Administrator."
  Say  "     Close this, right-click Restore-Classic.cmd, and pick"
  Say  "     'Run as administrator'."
  try { Stop-Transcript | Out-Null } catch {}
  exit 1
}
Ok "Running as Administrator."

# ---- 2. pending reboot gate --------------------------------------------
# A queued file-rename means Windows could not delete a locked file and has
# deferred it to next boot. Until the reboot happens, every reinstall hits the
# same error. Checking this FIRST is what stops the endless retry loop.
Head "Checking for a pending reboot"
$pending = $null
try {
  $pending = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' `
              -Name PendingFileRenameOperations -EA 0).PendingFileRenameOperations
} catch {}
if ($pending) {
  Bad "Windows has a file delete queued for the next restart."
  Say ""
  Say "  Nothing can fix the install until you reboot. Restart the computer," -ForegroundColor Yellow
  Say "  then run this again. It will continue from here." -ForegroundColor Yellow
  Say ""
  try { Stop-Transcript | Out-Null } catch {}
  exit 2
}
Ok "No pending reboot. Safe to continue."

# ---- 3. what we're about to do -----------------------------------------
$appData   = Join-Path $env:APPDATA        'Claude'
$localApp  = Join-Path $env:LOCALAPPDATA   'AnthropicClaude'
$pkgGlob   = Join-Path $env:LOCALAPPDATA   'Packages\*Claude*'
$backupDir = Join-Path ([Environment]::GetFolderPath('Desktop')) "Claude-backup-$stamp"

Head "Plan"
Say  "   1. Close Claude if it is running"
Say  "   2. Back up your settings to:"
Say  "      $backupDir" -ForegroundColor White
Say  "   3. Remove the broken install and its leftover data"
Say  "   4. Verify the blocking folder is really gone"
Say  "   5. Open the download page for a fresh install"
Say  ""
Say  "   Only Claude's own folders are touched. Browsers are not scripted."

if (-not $SkipPrompt) {
  Say ""
  $go = Read-Host "   Continue? (y/n)"
  if ($go -notmatch '^(y|yes)$') { Say "   Cancelled - nothing changed."; try { Stop-Transcript | Out-Null } catch {}; exit 0 }
}

# ---- 4. stop running processes -----------------------------------------
Head "Closing Claude"
$procs = Get-Process -Name 'claude','Claude' -EA 0
if ($procs) { $procs | Stop-Process -Force -EA 0; Start-Sleep -Seconds 2; Ok "Closed $($procs.Count) process(es)." }
else { Ok "Claude was not running." }

# ---- 5. back up settings BEFORE removing anything -----------------------
Head "Backing up your settings"
$backedUp = $false
if (Test-Path $appData) {
  New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
  try {
    Copy-Item $appData -Destination (Join-Path $backupDir 'Claude-appdata') -Recurse -Force -EA Stop
    $backedUp = $true
    Ok "Saved to $backupDir"
    $cfg = Join-Path $appData 'claude_desktop_config.json'
    if (Test-Path $cfg) { Ok "Your MCP/connector config is in that backup." }
  } catch { Warn "Could not copy settings: $($_.Exception.Message)" }
} else { Ok "No existing settings found - nothing to back up." }

# ---- 6. remove the install ---------------------------------------------
Head "Removing the broken install"
$pkgs = Get-AppxPackage *Claude* -EA 0
if ($pkgs) {
  foreach ($p in $pkgs) {
    try { Remove-AppxPackage -Package $p.PackageFullName -EA Stop; Ok "Removed package $($p.Name)" }
    catch { Warn "Could not remove $($p.Name): $($_.Exception.Message)" }
  }
} else { Ok "No Store/MSIX package registered." }

# Desktop-installer build (Update.exe lives beside the versioned app folders)
$uninst = Join-Path $localApp 'Update.exe'
if (Test-Path $uninst) {
  try { Start-Process $uninst -ArgumentList '--uninstall','-s' -Wait -EA Stop; Ok "Ran the app uninstaller." }
  catch { Warn "Uninstaller did not complete: $($_.Exception.Message)" }
}

Head "Clearing leftover data"
foreach ($t in @($pkgGlob, $localApp, $appData)) {
  $hits = Get-Item $t -EA 0
  if (-not $hits) { Ok "Already clear: $t"; continue }
  foreach ($h in $hits) {
    try { Remove-Item $h.FullName -Recurse -Force -EA Stop; Ok "Removed $($h.FullName)" }
    catch { Warn "Locked, will clear on reboot: $($h.FullName)" }
  }
}

# ---- 7. verify ----------------------------------------------------------
Head "Verifying"
$left = @()
foreach ($t in @($pkgGlob, $localApp, $appData)) { if (Get-Item $t -EA 0) { $left += $t } }
if ($left.Count -eq 0) {
  Ok "PASS - the folder that was blocking the install is gone."
} else {
  Bad "INCOMPLETE - still present:"
  $left | ForEach-Object { Say "        $_" -ForegroundColor Red }
  Say ""
  Say "  Reboot and run this once more. That clears a locked folder." -ForegroundColor Yellow
  try { Stop-Transcript | Out-Null } catch {}
  exit 3
}

# ---- 8. optionally restore settings ------------------------------------
if ($KeepSettings -and $backedUp) {
  Head "Putting your settings back"
  try {
    New-Item -ItemType Directory -Path $appData -Force | Out-Null
    Copy-Item (Join-Path $backupDir 'Claude-appdata\*') -Destination $appData -Recurse -Force -EA Stop
    Ok "Settings restored (connectors and MCP servers kept)."
  } catch { Warn "Could not restore settings: $($_.Exception.Message)" }
}

# ---- 9. reinstall + browser ---------------------------------------------
Head "Next: install the fresh copy"
Say  "   The download page is opening now. Install it once - this attempt is"
Say  "   the one that works, because the blocking folder is finally gone."
try { Start-Process 'https://claude.ai/download' } catch { Warn "Open https://claude.ai/download yourself." }

Head "Then: reset claude.ai in your browser"
Say  "   Do this by hand - a script that wipes browser data would take every"
Say  "   other saved login with it. Per-site only:"
Say  ""
Say  "   Chrome / Edge:  paste this in the address bar" -ForegroundColor White
Say  "     chrome://settings/content/all?searchSubpage=claude.ai" -ForegroundColor Cyan
Say  "     -> click claude.ai -> Delete data.  Edge uses edge://settings/..." -ForegroundColor Gray
Say  ""
Say  "   Then hard-reload claude.ai with Ctrl+Shift+R and sign in again." -ForegroundColor White
Say  "   That clears the stale cached interface without touching other sites." -ForegroundColor Gray

Head "Done"
if ($backedUp) { Say "   Your old settings: $backupDir" -ForegroundColor White }
Say  "   Full log: $logPath" -ForegroundColor DarkGray
Say ""
try { Stop-Transcript | Out-Null } catch {}
if (-not $SkipPrompt) { Read-Host "   Press Enter to close" | Out-Null }
exit 0
