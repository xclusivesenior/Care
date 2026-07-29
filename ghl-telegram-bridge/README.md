# GHL → Telegram Bridge

A tiny, **zero-dependency** Node service that connects your GoHighLevel (GHL)
account to your **own** Telegram bot. GHL sends a webhook to this bridge, and the
bridge posts a nicely formatted message to your Telegram chat.

It can:
- 📥 Post **new-lead notifications** from GHL
- 💬 Post **any free-text message** from a GHL workflow
- 🌐 Run a **bilingual SMS audit** (English vs. English+Spanish) and post the report

Your bot token stays in a private `.env` file that is **never** committed.

---

## 1. Get your two values

1. **Bot token** — in Telegram, open **BotFather** → `/mybots` → your bot → **API Token**.
2. **Chat ID** — add your bot to the target group and send any message there, then:
   ```bash
   cp .env.example .env
   # put your TELEGRAM_BOT_TOKEN into .env, then:
   npm run chat-id
   ```
   It prints the chat IDs your bot can see. Put the right one in `.env` as
   `TELEGRAM_CHAT_ID` (group IDs are usually negative).

## 2. Configure

```bash
cp .env.example .env      # if you didn't already
# edit .env: TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID, (optional) WEBHOOK_SECRET
```

## 3. Run

```bash
node server.js
# [bridge] listening on port 3000
```

Test it locally:
```bash
curl -X POST http://localhost:3000/ghl/notify \
  -H "Content-Type: application/json" \
  -d '{"text":"Hello from the bridge ✅"}'
```
You should see the message appear in your Telegram chat.

## 4. Make it reachable by GHL

GHL needs a public URL to call. Options:
- Run it on a small always-on server/VPS and use its public URL.
- Run it on your desktop and expose it with a tunnel (e.g. `cloudflared tunnel`
  or `ngrok http 3000`) — good for testing.
- Any host that runs Node 18+.

You'll get a public base URL like `https://your-host` — use that below.

## 5. Connect it in GHL

In a GHL **Workflow**, add a **Webhook** action:

| Purpose | Method | URL |
|---------|--------|-----|
| New lead alert | POST | `https://your-host/ghl/lead` |
| Free-text message | POST | `https://your-host/ghl/notify` |
| Bilingual audit | POST | `https://your-host/ghl/audit` |

If you set `WEBHOOK_SECRET` in `.env`, append `?key=YOUR_SECRET` to the URL.

### Payload examples

**Lead** (`/ghl/lead`) — map GHL contact fields, or just send the contact object.
The formatter looks for common keys (`first_name`, `last_name`, `phone`, `email`, `source`):
```json
{ "first_name": "{{contact.first_name}}", "last_name": "{{contact.last_name}}",
  "phone": "{{contact.phone}}", "email": "{{contact.email}}" }
```

**Notify** (`/ghl/notify`):
```json
{ "text": "Appointment confirmed for {{contact.first_name}} at {{appointment.time}}" }
```

**Audit** (`/ghl/audit`) — send your SMS templates and get a bilingual report:
```json
{ "messages": [
  { "name": "Welcome", "text": "Hi {{contact.first_name}}, welcome to Xclusive Senior!" },
  { "name": "Reminder", "text": "Recordatorio: su cita es mañana. Reminder: your appointment is tomorrow." }
] }
```

## Endpoints summary

| Route | Does |
|-------|------|
| `GET /` | health check |
| `POST /ghl/lead` | format + send a lead notification |
| `POST /ghl/notify` | send a free-text message |
| `POST /ghl/audit` | run bilingual audit, post the report |

## Notes

- The bilingual detector is a **local heuristic** for English + Spanish — a fast
  first pass. Eyeball anything marked "unclear."
- Keep `.env` private. If a token ever leaks, regenerate it in BotFather (`/revoke`).
- This mirrors what Sergio's "Apex" bot does, but points at **your** bot and
  chat, so you own the pipeline.
