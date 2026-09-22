# Restore Claude to a clean setup

For when Claude Desktop is broken, half-installed, or stuck after a failed
update — including the `0x80073D05` loop — and you want it back to working the
way it used to, on the computer **and** in your browser.

---

## Read this first

There is **no official way to install a specific older ("classic") build** of
Claude Desktop, and claude.ai has **no classic-interface switch**. Anyone
offering you an old installer download is not a source to trust with an app
you sign into.

So "back to classic" here means the thing that actually fixes it: **a clean
install of the current app, plus a fresh browser state.** That clears the
stale, half-broken setup that's causing the symptoms.

If what you actually want is an older *look* that Anthropic has since changed,
no script can bring that back — that's a product change, not a fault on your
machine.

---

## Do this

1. Download this folder to your computer (both files, kept together).
2. **Double-click `Restore-Classic.cmd`.**
3. Click **Yes** when Windows asks for administrator rights.
4. Read what it says it will do, then press `y`.

It closes Claude, backs up your settings to your Desktop, removes the broken
install and the leftover folder that blocks reinstalls, checks the folder is
really gone, and opens the download page.

Install once more. That attempt is the one that works.

---

## If it says "REBOOT FIRST"

**Restart the computer, then run it again.** This is not optional and it is not
the script giving up.

When Windows can't delete a locked file, it doesn't fail — it queues the delete
for the next boot. Until you actually restart, the old folder is still sitting
there, so every reinstall hits the identical error. This is why reinstalling
five times changes nothing. Only the reboot clears it.

---

## Then reset claude.ai in your browser

The script deliberately does **not** touch your browser. A script that wipes
browser data takes every saved login on the machine with it. Do this one by
hand — it only affects claude.ai:

**Chrome** — paste in the address bar:
```
chrome://settings/content/all?searchSubpage=claude.ai
```
Click `claude.ai` → **Delete data**.

**Edge** — same thing, with `edge://` instead of `chrome://`.

**Safari** — Settings → Privacy → Manage Website Data → search `claude` → Remove.

**Firefox** — Settings → Privacy & Security → Cookies and Site Data → Manage
Data → search `claude` → Remove Selected.

Then open claude.ai and hard-reload with **Ctrl+Shift+R** (Mac: **Cmd+Shift+R**)
and sign in again. That drops the cached interface without disturbing any other
site.

---

## Your settings are safe

Before removing anything, your config is copied to:

```
Desktop\Claude-backup-<date>-<time>\
```

That includes `claude_desktop_config.json` — your connectors and MCP servers.
Nothing is deleted until after that copy succeeds.

Want them carried straight over to the fresh install instead? Run it as:

```powershell
powershell -ExecutionPolicy Bypass -File .\Restore-Classic.ps1 -KeepSettings
```

Worth knowing: if a bad setting is *causing* the breakage, keeping it brings the
problem with it. Start without `-KeepSettings`, confirm Claude opens, then copy
your config back from the backup folder.

---

## What the endings mean

| It says | Meaning | Do |
|---|---|---|
| `PASS` | Blocking folder is gone | Install from the page it opened |
| `REBOOT FIRST` | A delete is queued for next boot | Restart, run it again |
| `INCOMPLETE` | A folder is still locked | Restart, run it again |
| `Not running as Administrator` | Launched without rights | Use `Restore-Classic.cmd`, click Yes |

A full log is written to `%TEMP%\ClaudeRestore-<timestamp>.log`.

---

## Verified before it reached you

`Restore-Classic.ps1` and the paste-able one-liner both parse clean under
PowerShell 7.6.6, and the one-liner's logic was run against mocked Windows
cmdlets in three scenarios (`test/Test-OneLiner.ps1`):

| Scenario | Prints | Settings backed up | Folders removed | Opens download |
|---|---|---|---|---|
| Pending reboot | `REBOOT FIRST` | — nothing touched — | no | no |
| Clean run | `PASS` | yes | yes | yes |
| Folder stays locked | `INCOMPLETE` | yes | no | **no** |

The two that matter: on a pending reboot it changes nothing at all, and when a
folder is still locked it refuses to tell you the install will work.

What could not be tested here: this container is Linux, so the Windows-only
calls (`Get-AppxPackage`, the registry read, the elevation prompt) were mocked
rather than exercised for real. They are standard calls, but the first true
end-to-end run is yours.

---

## Related

`claude-desktop-fix/` on the `claude/app-install-error-0x80073d05-5ce2km`
branch has the narrower repair for `0x80073D05` alone, plus paste-able
one-liners if you'd rather not download files. This folder is the fuller
"put it back to a clean state" version.
