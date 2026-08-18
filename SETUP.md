# Setup — Start Here

**Your goal:** run the business from your phone, and not depend on the computer.

That's achievable, but one fact drives the whole plan:

> The bridge in this repo is a **web server**. GoHighLevel calls it over the
> internet whenever a lead comes in. Something has to be awake and reachable at
> that moment.
>
> - If that "something" is **your computer**, the computer must stay powered on,
>   awake, and running a tunnel — forever. You'd need the computer *more*, not less.
> - If that "something" is a **cloud host**, it runs 24/7 for free, and your
>   computer becomes optional.

So: **put the bot in the cloud, and treat the computer as a nice-to-have.**

---

## The three pieces

| Piece | Where it lives | Do you need the computer? |
|-------|----------------|---------------------------|
| **The bot** (GHL → Telegram bridge) | Render (cloud) | No — set up in a browser |
| **The code** (this repo) | GitHub | No — edit in browser or Claude Code on the web |
| **The Chrome bar** (`ghl-bilingual-checker`) | Chrome on a desktop | Yes — Chrome extensions are desktop-only |

Only the third piece genuinely needs a computer, and it's optional — it's a
convenience bar for auditing SMS inside GHL. Everything that has to run
around the clock goes in the cloud.

---

## Do it in this order

### 1. Get the bot into the cloud → **[PHONE-PLAYBOOK.md](PHONE-PLAYBOOK.md)**
Browser-only, works from your phone. About 15 minutes. After this, the bot
posts leads to Telegram whether your computer is on or off.

**Do this first.** It's the part that actually reaches your goal.

### 2. Set up the computer workspace → **[COMPUTER-SETUP.md](COMPUTER-SETUP.md)**
Windows and Mac, side by side. Optional, but worth doing once. It gives you a
place to test changes safely before they go live, and it's where the Chrome bar
gets installed.

### 3. Keep taking ownership → **[OWNERSHIP-TRANSFER-CHECKLIST.md](OWNERSHIP-TRANSFER-CHECKLIST.md)**
None of this matters if someone else can still turn off the accounts
underneath it.

---

## What "synced" actually means here

There's no magic sync between your phone and your computer. What you get
instead is one shared source of truth — **GitHub** — that all three surfaces
read from and write to:

```
                    ┌──────────────┐
       phone ─────► │              │ ◄───── computer (optional)
                    │    GitHub    │
       Render ◄──── │  (the truth) │
      (the live bot)└──────────────┘
```

- Change something on your phone → push to GitHub → **Render redeploys itself
  automatically.** Nothing to do on the computer.
- Change something on the computer → push to GitHub → same thing.
- Sit down at the computer after a week away → `git pull` → you have whatever
  your phone did.

The one rule that keeps this working: **always let GitHub be the middleman.**
Don't keep edits sitting only on the computer, or only on the phone.

---

## Security note that applies everywhere

Your Telegram bot token and GHL keys are **never** committed to this repo.
They live in two places only:

1. Render's environment-variable settings (for the live bot)
2. A local `.env` file on your computer, which is git-ignored (for testing)

If a token ever leaks, regenerate it — BotFather `/revoke` for Telegram, and
regenerate the key in GHL. Then update it in Render.
