# Computer Setup — Windows & Mac

**Read [PHONE-PLAYBOOK.md](PHONE-PLAYBOOK.md) first.** That's the part that gets
the bot running 24/7 without this machine. This page is the *optional* second
step: a workspace for testing changes before they go live, and the one place the
Chrome bar can be installed.

Do this once. After that the computer can sit in a drawer.

Commands are given for both platforms. Run them in **PowerShell** (Windows) or
**Terminal** (Mac).

---

## 1. Install the three tools

| Tool | Why | Windows | Mac |
|------|-----|---------|-----|
| **Git** | Sync with GitHub | `winget install Git.Git` | `xcode-select --install` |
| **Node 20+** | Runs the bridge | `winget install OpenJS.NodeJS.LTS` | `brew install node` |
| **VS Code** | Edit files | `winget install Microsoft.VisualStudioCode` | `brew install --cask visual-studio-code` |

> **Mac without Homebrew?** Install it first with the one-line command at
> [brew.sh](https://brew.sh), or just download Node from
> [nodejs.org](https://nodejs.org) — the installer works fine.
>
> **Windows without winget?** Download each from git-scm.com, nodejs.org, and
> code.visualstudio.com.

**Close and reopen your terminal**, then check both landed:

```bash
git --version     # expect: git version 2.x
node --version    # expect: v20.x or higher
```

If `node --version` says something below v20, the bridge won't run — install the
current LTS from nodejs.org.

---

## 2. Get the code

```bash
# Windows
cd $HOME\Documents
# Mac
cd ~/Documents

git clone https://github.com/xclusivesenior/Care.git
cd Care
```

Git will ask you to sign in to GitHub the first time. Use a browser sign-in if
offered — it's the least painful path.

Tell git who you are (once per machine):

```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

---

## 3. Set up your local secrets

The bridge reads a `.env` file that is **git-ignored** — it never leaves your
machine and never reaches GitHub.

```bash
# Windows
cd ghl-telegram-bridge
copy .env.example .env

# Mac
cd ghl-telegram-bridge
cp .env.example .env
```

Open `.env` in VS Code (`code .env`) and fill in:

```
TELEGRAM_BOT_TOKEN=<the token from BotFather>
TELEGRAM_CHAT_ID=<the negative number from the playbook>
PORT=3000
WEBHOOK_SECRET=
```

> **Use a separate test bot and test group here.** Make a second bot in
> BotFather and a private group with just you in it. Then your experiments never
> spam the real "Xclusive marketing" group. Worth the five minutes.

---

## 4. Run it locally

```bash
node server.js
```

You should see `[bridge] listening on port 3000`. Leave it running and open a
**second** terminal window to test:

```bash
curl -X POST http://localhost:3000/ghl/notify \
  -H "Content-Type: application/json" \
  -d "{\"text\":\"Hello from my computer\"}"
```

A message appears in your test Telegram group. Press `Ctrl+C` in the first
window to stop the server.

> On Windows, PowerShell's `curl` is an alias for something else and will
> complain. Either use `curl.exe` explicitly, or run the command in **Git Bash**
> (installed with Git).

That's the entire local setup. There's no build step and no dependencies to
install — the bridge is plain Node.

---

## 5. Install the Chrome bar (desktop-only)

This is the one feature that genuinely can't move to your phone.

1. Open Chrome → `chrome://extensions`
2. Turn on **Developer mode** (top-right toggle)
3. Click **Load unpacked**
4. Select the `ghl-bilingual-checker` folder inside your `Care` folder

The bar shows up when you're in GHL. See
[`ghl-bilingual-checker/README.md`](ghl-bilingual-checker/README.md) for what it
does.

---

## 6. The only git routine you need

**Every time you sit down at the computer**, before touching anything:

```bash
git pull
```

That pulls in whatever you did from your phone. Skipping this is how you end up
with conflicting versions.

**When you've made a change you want live:**

```bash
git add -A
git commit -m "describe what you changed"
git push
```

Pushing to `main` makes Render redeploy on its own within a minute or two. Check
the Render dashboard (or just load your Render URL) to confirm it came back up.

**Golden rule:** never leave work sitting only on this computer. Push it, or
it doesn't exist as far as your phone is concerned.

---

## Optional: test against real GHL webhooks

To have GHL call the copy running on *your machine* instead of the live cloud
one, you need a temporary public tunnel:

```bash
# Windows
winget install Cloudflare.cloudflared
# Mac
brew install cloudflared

cloudflared tunnel --url http://localhost:3000
```

It prints a temporary `https://something.trycloudflare.com` URL. Paste that into
a GHL **test** workflow.

Two cautions: the URL dies when you close the terminal, and pointing your **real**
GHL workflows at it means leads stop arriving the moment you shut the laptop.
Only ever use a tunnel for testing. Production stays on Render.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `node: command not found` | Terminal opened before install | Close and reopen the terminal |
| `Cannot find module './lib/telegram'` | Wrong folder | `cd` into `ghl-telegram-bridge` first |
| Server starts, no Telegram message | Bad token or chat ID | Re-check `.env`; the chat ID usually starts with `-` |
| `401 Bad or missing secret` | `WEBHOOK_SECRET` is set locally | Either clear it in `.env` or add `?key=YOUR_SECRET` to the URL |
| `EADDRINUSE` on port 3000 | Server already running | Close the other terminal, or set `PORT=3001` in `.env` |
| `git push` rejected | Phone changes landed first | Run `git pull`, resolve, push again |
