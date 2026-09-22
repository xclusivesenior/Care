$body = Get-Content "oneliner.txt" -Raw
$root = Join-Path ([System.IO.Path]::GetTempPath()) "cr-test"

function New-Scenario([string]$name,[bool]$pendingReboot,[bool]$removeWorks){
  Remove-Item $root -Recurse -Force -EA 0
  $env:USERPROFILE  = Join-Path $root "user";  $null = New-Item -ItemType Directory (Join-Path $env:USERPROFILE "Desktop") -Force
  $env:APPDATA      = Join-Path $root "roam";  $null = New-Item -ItemType Directory (Join-Path $env:APPDATA "Claude") -Force
  $env:LOCALAPPDATA = Join-Path $root "local"
  $null = New-Item -ItemType Directory (Join-Path $env:LOCALAPPDATA "AnthropicClaude") -Force
  $null = New-Item -ItemType Directory (Join-Path $env:LOCALAPPDATA "Packages\AnthropicClaude_x") -Force
  Set-Content (Join-Path $env:APPDATA "Claude\claude_desktop_config.json") '{"mcpServers":{"keep":"me"}}'

  $script:pending = $pendingReboot
  # Only stub the Windows-only cmdlets. Remove-Item stays REAL unless we are
  # deliberately simulating a locked folder.
  $stub = @'
function Get-ItemProperty { if($script:pending){[pscustomobject]@{PendingFileRenameOperations='x'}}else{[pscustomobject]@{PendingFileRenameOperations=$null}} }
function Get-AppxPackage  { @() }
function Remove-AppxPackage { }
function Get-Process { param([Parameter(ValueFromRemainingArguments=$true)]$a) @() }
function Stop-Process { }
function Start-Process { param([Parameter(ValueFromRemainingArguments=$true)]$a) $script:opened = ($a -join ' ') }
'@
  if(-not $removeWorks){ $stub += "`nfunction Remove-Item { }" }   # simulate a locked folder

  $script:opened = $null
  $out = & ([scriptblock]::Create($stub + "`n" + $body)) 2>&1
  $backup = Get-ChildItem (Join-Path $env:USERPROFILE "Desktop") -Filter "Claude-backup-*" -EA 0 | Select-Object -First 1
  $cfg = if($backup){ Get-ChildItem $backup.FullName -Recurse -Filter "claude_desktop_config.json" -EA 0 }
  [pscustomobject]@{
    Scenario    = $name
    Result      = ($out | Where-Object { $_ -is [string] } | Select-Object -Last 1)
    Backup      = [bool]$backup
    ConfigKept  = [bool]$cfg
    FoldersGone = -not (Test-Path (Join-Path $env:LOCALAPPDATA "AnthropicClaude"))
    OpenedPage  = [bool]$script:opened
  }
}

@(
  New-Scenario "pending reboot"      $true  $true
  New-Scenario "clean run"           $false $true
  New-Scenario "folder stays locked" $false $false
) | Format-Table -AutoSize | Out-String -Width 200
