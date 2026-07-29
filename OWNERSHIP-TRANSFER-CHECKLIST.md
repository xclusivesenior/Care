# Ownership Transfer Checklist — Xclusive Senior

Purpose: take full ownership of every account, bot, and integration used to run
the business, so nothing depends on another person's login, credits, or billing.

**Legend:** ✅ already yours · 🔄 needs transfer from Sergio · 🔒 security action you can do yourself

---

## 1. Platforms you already own ✅

You hold the username + password for these, so you can't be locked out.
Sergio does **not** have the passwords.

- [ ] **Outlook / Microsoft email**
- [ ] **QuickBooks**
- [ ] **Meta** (Facebook / Instagram)
- [ ] **TikTok**

> ⚠️ Important: "he doesn't have the password" is **not** the same as "he has no
> access." When the automation was connected to these, each platform gave it a
> live connection (token). That connection can still read/post on your behalf
> **without** the password. See Section 4 to review and revoke those.

---

## 2. In Sergio's hands — needs transfer 🔄

### Telegram bot (the @username)
- [ ] Sergio: BotFather → `/mybots` → the bot → **Bot Settings → Transfer Ownership** → your account
- [ ] (Requires Sergio to have 2-Step Verification enabled on Telegram)
- [ ] After transfer: you can see it under your own `/mybots`

### Telegram group ("Xclusive marketing")
- [ ] Sergio: open group → members → tap **your name** → **Promote to Admin**
- [ ] Then enable **Transfer Group Ownership** to you

### Backend automation account (the bot's "brain" + credits) ⭐ biggest piece
This is the service that makes the bot reply and connects it to GoHighLevel —
and the thing that "ran out of credit."

- [ ] Identify the platform it runs on (n8n / Make / Zapier / Voiceflow / Botpress / custom server / other): __________________
- [ ] Get the account **login transferred** to you, OR be added as **Owner/Admin**
- [ ] Move **billing / payment method** to your own card
- [ ] Confirm you can top up **credits** yourself

---

## 3. GoHighLevel (GHL)

- [ ] Confirm the **account / agency owner** is you (not Sergio)
- [ ] Check any **API keys / Private Integration tokens** the bot uses — were they
      created under **your** GHL or Sergio's?
- [ ] If Sergio's: regenerate them under your account and update the automation
- [ ] Confirm any **phone numbers** (Twilio / LC Phone) are under your billing

---

## 4. Security — cut any access you don't control 🔒

You can do all of these yourself, right now, without Sergio. Review what's
connected to each platform and remove anything you don't recognize:

- [ ] **Meta:** Settings → Security → **Business Integrations / Apps and Websites** → review + remove
- [ ] **TikTok:** Settings → Security & permissions → **Manage app permissions**
- [ ] **QuickBooks:** Settings → **Apps / Connected apps** → disconnect unknowns
- [ ] **Outlook / Microsoft:** account.microsoft.com → Privacy/Security → **Apps and services with access** → revoke
- [ ] Change passwords on any platform where you're unsure who has had access
- [ ] Turn on **2-Step Verification** everywhere

---

## 5. The plumbing (easy to forget)

- [ ] **Phone numbers** (Twilio / LC Phone) → your billing
- [ ] **Domains** → your registrar account
- [ ] **Email sending / SMTP** → your account
- [ ] **Hosting / servers** → your account
- [ ] **Payment methods** on every service → your card

---

## What to ask Sergio (copy/paste)

> Hi Sergio — I'm consolidating ownership of the business accounts. Could you:
> 1. Transfer the Telegram bot to me (BotFather → Transfer Ownership).
> 2. Make me owner of the "Xclusive marketing" Telegram group.
> 3. Tell me what platform the bot's automation runs on, and transfer that
>    account (and its billing) to me — or add me as owner.
> 4. Send me any GoHighLevel API keys/tokens you set up, or let me know so I can
>    regenerate them under my account.
> Thanks!

---

## Fallback if transfers get messy

If sorting out Sergio's accounts/credits becomes a hassle, the clean alternative
is to run **your own** bot + automation from scratch (see the `ghl-telegram-bridge/`
folder in this repo). Then you depend on no one else's login, credits, or billing.
