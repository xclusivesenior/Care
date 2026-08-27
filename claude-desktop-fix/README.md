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

## Just fix it (one double-click)

If you have reinstalled several times and keep landing on the same error,
**stop reinstalling** — each attempt fails at the identical step, because
nothing has removed the folder that is blocking it. Break the loop first:

> Double-click **`Fix-Claude.cmd`** in this folder.

It asks for administrator rights, clears the stale app-data store, restores
your desktop shortcut if the app is still installed, tells you if it isn't,
and offers to open the download page. Then install once more — that attempt
is the one that works.

The sections below explain what it does and cover the cases where it doesn't.

---

## Why the same error repeats every single time

If you have reinstalled several times and got byte-identical errors, that is a
signal, not bad luck. The usual cause is a **pending reboot**.

When Windows cannot delete a locked file, it does not fail — it queues the
delete for the next boot (`PendingFileRenameOperations`). Until you actually
reboot, the old app-data folder is still there, so the next install hits
`0x80073D05` again. And again. Reinstalling can never clear it; only a reboot
can.

`Repair-ClaudeDesktopInstall.ps1` now checks for this **before** doing any
work and tells you to reboot first if a rename is queued. It also verifies at
the end that the blocking folder is really gone, printing `PASS` or
`INCOMPLETE` rather than a vague "Done", and writes a full transcript to
`%TEMP%\ClaudeRepair-<timestamp>.log`.

So the reliable order is:

1. Run the repair (or `Fix-Claude.cmd`).
2. **Reboot** — this is the step that is easy to skip and the one that matters.
3. Install once.

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

## The desktop icon disappeared

This is the same event as the error, not a second failure. `0x80073D05`
usually hits during an **update**: Windows removes the existing install, then
fails to write the replacement. Half-removed app, no icon.
(`Repair-ClaudeDesktopInstall.ps1` also removes the package by design, so
running it has the same visible effect until you reinstall.)

Two 10-second checks first. If *every* desktop icon vanished, not just Claude,
this has nothing to do with Claude: right-click the desktop → **View** →
**Show desktop icons**. And check the Recycle Bin — if the `.lnk` is in there,
just restore it.

Otherwise, run:

```powershell
cd path\to\Care\claude-desktop-fix
.\Restore-ClaudeDesktopShortcut.ps1
```

It reports which situation you are actually in and fixes the recoverable one:

| Finding | What happens |
| --- | --- |
| `claude.exe` present under `%LOCALAPPDATA%\AnthropicClaude` | Only the shortcut was lost — the script recreates it on your desktop. |
| Store package registered, no `.exe` path | Store builds have no fixed executable path to point a `.lnk` at. Launch from the Start menu and drag that entry to the desktop. |
| Neither found | The app really is gone. Reinstall from <https://claude.ai/download>; with the broken package now cleared, the direct installer goes through. |

No elevation needed, and it supports `-WhatIf`.

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
