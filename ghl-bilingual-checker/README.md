# GHL Bilingual SMS Checker (Chrome bar)

A tiny Chrome extension that adds a **bar** inside your browser. While you are
logged into GoHighLevel, it scans the SMS / message text on the page and tells
you which messages are **bilingual (English + Spanish)** and which are
**English-only**.

Nothing is sent anywhere — all checking happens locally in your browser. You
stay logged into your own CRM; the bar just reads what's already on screen.

## Install (takes ~1 minute)

1. Open Chrome and go to `chrome://extensions`.
2. Turn on **Developer mode** (toggle, top-right).
3. Click **Load unpacked**.
4. Select this `ghl-bilingual-checker` folder.
5. You'll now see a blue **🌐 Bilingual SMS** button at the bottom-right of every page.

## How to use

1. Log into GoHighLevel as usual.
2. Open where your SMS text lives:
   - **Automation → Workflows** → click an **SMS** action step
   - **Marketing → Templates** (SMS templates)
   - A **Conversation** with sent SMS
3. Click the **🌐 Bilingual SMS** button, then **Scan page**.
4. Read the results:
   - ✅ **Bilingual** — has both English and Spanish
   - ⚠️ **English only** — needs a Spanish version added
   - 📋 **Spanish only** / ❔ Unclear
5. You can also paste a single message into the box and click **Check text below**.

> Tip: GHL loads steps one at a time, so scan each workflow step / template
> view. The summary line tallies bilingual vs. English-only for what's on screen.

## How detection works

It's a local heuristic: it looks for Spanish signals (accented characters,
`¿`/`¡`, and common Spanish words like *cita, recordatorio, gracias*) and
English signals (common English words). A message counts as **bilingual** when
both are present. It's meant as a fast first pass — eyeball anything it marks
"unclear."

## Limitations

- It reads what's rendered on the page; collapsed/unopened workflow steps won't
  be scanned until you open them.
- The heuristic targets **English + Spanish**. Tell the maintainer if you need
  another language pair and the word lists in `content.js` can be extended.
