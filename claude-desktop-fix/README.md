# Fix: Claude Desktop install fails with `0x80073D05`

```
An internal error occurred with error 0x80073D05.
See http://go.microsoft.com/fwlink/?LinkId=235160 for help diagnosing
app deployment issues. (0x80073d05)
```

## What the code actually means

`0x80073D05` is `ERROR_DELETING_EXISTING_APPLICATIONDATA_STORE_FAILED`.

Windows is **not** failing to download or unpack the app. It is failing to
delete the *leftover app-data folder* from a previous install of the same
package before writing the new one. Something is holding that folder open,
or the folder's permissions no longer let Windows touch it (very common after
a failed update, a killed installer, or an antivirus quarantine).

So: retrying the installer will keep failing until the stale folder is gone.

---

## Fastest path (recommended)

The `0x80073D05` failure only affects the **MSIX / Microsoft Store** flavour of
the app. The direct desktop installer from Anthropic is a plain Windows
installer and does not use the AppX deployment pipeline at all — it sidesteps
this error completely.

1. Uninstall any partially-installed Claude entry:
   **Settings → Apps → Installed apps → Claude → Uninstall**
2. Download the desktop installer from <https://claude.ai/download>
3. Run `Claude-Setup-x64.exe`.

If you specifically need the Store version, do the full repair below.

---

## Full repair (Store / MSIX version)

Run **Windows PowerShell as Administrator**, then:

```powershell
cd path\to\Care\claude-desktop-fix
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
.\Repair-ClaudeDesktopInstall.ps1
```

The script does, in order:

1. Closes any running `claude*` process that would keep the data store locked.
2. Removes the package for the current user and for all users
   (`Remove-AppxPackage` / `Remove-AppxProvisionedPackage`).
3. Takes ownership of the orphaned
   `%LOCALAPPDATA%\Packages\<PackageFamilyName>` folder and deletes it.
   **This is the step that actually clears `0x80073D05`.**
4. Clears the Store download cache (`wsreset.exe`).
5. Re-registers the Store/AppX stack so deployment works again.

Add `-WhatIf` to see what it would do without changing anything:

```powershell
.\Repair-ClaudeDesktopInstall.ps1 -WhatIf
```

Reboot, then install again.

---

## If it still fails

Read the real error instead of guessing — the AppX log is far more specific
than the installer dialog:

```powershell
Get-AppxLog -All | Select-Object -First 40 | Format-List
```

Common causes it will surface:

| What the log shows | Fix |
| --- | --- |
| `Access is denied` on a `Packages\...` path | The folder is owned by a deleted user profile. Step 3 of the script fixes it; if not, take ownership of `%LOCALAPPDATA%\Packages` itself. |
| A file is `in use` | An antivirus or backup agent has the folder open. Pause real-time protection, reboot, retry. |
| `The system cannot find the path specified` | `%LOCALAPPDATA%\Packages` is redirected (roaming profile / OneDrive Known Folder Move). Un-redirect it before installing. |
| Errors mentioning `StateRepository` | Run `sfc /scannow`, then `DISM /Online /Cleanup-Image /RestoreHealth`, reboot. |

Windows also needs to be recent enough for the app; on older Windows 10 builds
run Windows Update first.
