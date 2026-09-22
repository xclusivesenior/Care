# Phone Playbook — run everything without the computer

Everything below is done in a **web browser**. Your phone's browser is fine.
Nothing here requires the computer to be on.

---

## ⚠️ Do this first: give the repo a `main` branch

Right now this repo has **no `main` branch** — all the code sits on a temporary
`claude/...` session branch. That's fine for drafting, but it's a shaky
foundation for a live bot, because Render needs one stable branch to watch.

From your phone:

1. Open **github.com/xclusivesenior/Care** → **Pull requests** → **New pull request**
2. Open a PR from the `claude/...` branch that has the latest work
3. Merge it. If GitHub says there's no base branch to merge into, go to
   **Settings → Branches** and create/rename the default branch to `main` first.
4. From then on, **`main` = what's live.** Session branches are drafts that get
   merged into it.

Why it matters: Render redeploys when `main` changes. If the code only ever
lives on throwaway branches, the live bot silently never updates.

---

## Step 1 — Collect your two Telegram values

**Bot token:** In Telegram, message **@BotFather** → `/mybots` → your bot →
**API Token**. Copy it.

**Chat ID:** Add the bot to your target group and send any message in that
group. Then open this in your phone's browser, pasting your token in:

```
https://api.telegram.org/bot<YOUR_TOKEN_HERE>/getUpdates
```

You'll get a wall of JSON. Look for `"chat":{"id":-1001234567890`. That negative
number is your **chat ID**. Copy it.

> No computer needed — that URL works fine in a phone browser. It replaces the
> `npm run chat-id` script from the README.

Keep both values somewhere private (a password manager, not a text message).

---

## Step 2 — Deploy to Render

1. Go to **render.com** and sign up **with your GitHub account** (this is the
   account that will own the bot — make sure it's *yours*, not Sergio's).
2. **New +** → **Blueprint**
3. Connect the **xclusivesenior/Care** repo. Render finds the `render.yaml`
   already in this repo and reads the whole configuration from it.
4. Render will prompt you for the two secrets it won't guess:
   - `TELEGRAM_BOT_TOKEN` → paste your token
   - `TELEGRAM_CHAT_ID` → paste your chat ID (include the minus sign)
5. Click **Apply**. Wait for the build to go green (a minute or two).
6. Set the branch it watches: service → **Settings → Branch** → `main`.

You now have a public URL like `https://ghl-telegram-bridge.onrender.com`.

**Test it right now from your phone:** open that URL in your browser. You should
see:

```json
{"ok":true,"service":"ghl-telegram-bridge","endpoints":["/ghl/lead","/ghl/notify","/ghl/audit"]}
```

If you see that, the bot is live and your computer had nothing to do with it.

### Grab your webhook secret

Render auto-generated a `WEBHOOK_SECRET` for you. Find it under
service → **Environment** → reveal `WEBHOOK_SECRET`. Copy it — you need it in
the next step. It's what stops strangers from posting into your Telegram group.

---

## Step 3 — Point GoHighLevel at it

In GHL, open a **Workflow** → add a **Webhook** action. Use `POST` and pick the
URL for what you want:

| What you want | URL |
|---------------|-----|
| New lead alert | `https://YOUR-APP.onrender.com/ghl/lead?key=YOUR_SECRET` |
| Free-text message | `https://YOUR-APP.onrender.com/ghl/notify?key=YOUR_SECRET` |
| Bilingual SMS audit | `https://YOUR-APP.onrender.com/ghl/audit?key=YOUR_SECRET` |

Replace `YOUR-APP` with your Render URL and `YOUR_SECRET` with the
`WEBHOOK_SECRET` value.

For a lead alert, set the webhook body to:

```json
{ "first_name": "{{contact.first_name}}", "last_name": "{{contact.last_name}}",
  "phone": "{{contact.phone}}", "email": "{{contact.email}}" }
```

Then hit GHL's **Test** button on the webhook action. A message should land in
your Telegram group. That's the whole loop working, phone-only.

> GHL's workflow builder is cramped on a phone. If it fights you, use your
> browser's **"Request desktop site"** option — it's usable that way.

---

## About the free tier (the one real catch)

Render's free plan **puts the service to sleep after ~15 minutes with no
traffic.** The next request wakes it, which takes roughly 30–60 seconds.

What that means in practice: if a lead comes in after a quiet stretch, the
Telegram alert may show up about a minute late. Nothing is lost — just delayed.

If a one-minute delay on a real lead is a problem, upgrade the service to
**Starter ($7/month)** in Render → **Settings → Instance Type**. It then never
sleeps and alerts are instant. You can also change `plan: free` to
`plan: starter` in `render.yaml`.

Don't bother with "keep-alive pinger" tricks — they're against the spirit of the
free tier and they break at the worst moment.

---

## Day-to-day, from the phone

**See if the bot is alive:** open your Render URL. `{"ok":true,...}` means yes.

**Read the logs (why didn't a message send?):** Render dashboard → your service
→ **Logs**. Works fine on mobile.

**Change the code:** two options, both phone-friendly.
- *Small edits:* on github.com, open the file → pencil icon → edit → commit to
  `main`. Render redeploys automatically.
- *Anything real:* **claude.ai/code** — start a session on this repo and describe
  what you want. It writes the change and opens a PR you merge from your phone.

**Change a token or secret:** Render → **Environment** → edit → save. The service
restarts on its own. Never put secrets in the repo.

**Rotate a leaked bot token:** BotFather → `/revoke` → get a new token → paste it
into Render's `TELEGRAM_BOT_TOKEN`. Done in two minutes, no computer.

---

## What still needs a computer

Being straight with you — one thing doesn't move to the phone:

**The Chrome bar** (`ghl-bilingual-checker/`). Chrome extensions only install on
desktop Chrome; mobile Chrome doesn't support them at all. There's no workaround.

The good news: it's optional. It's a convenience overlay for auditing SMS
templates inside GHL. The same audit runs in the cloud through the
`/ghl/audit` endpoint, which you can trigger from a GHL workflow — no computer
in the loop. Use the Chrome bar when you happen to be at a desk; don't build
your workflow around it.
