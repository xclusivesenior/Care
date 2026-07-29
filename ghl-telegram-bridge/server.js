"use strict";
/* GHL -> Telegram bridge (zero dependencies).
 *
 * Receives GoHighLevel webhooks and posts formatted messages to a Telegram
 * chat. Also exposes a bilingual-audit endpoint that classifies SMS text as
 * bilingual / English-only and posts the report to Telegram.
 *
 * Config comes from environment variables (see .env.example). Nothing secret
 * is committed to the repo.
 */
const http = require("http");
const fs = require("fs");
const path = require("path");
const { sendMessage, escapeHtml } = require("./lib/telegram");
const { audit } = require("./lib/bilingual");

// ---- Load .env (tiny parser, no dependency) ----------------------------
(function loadEnv() {
  const envPath = path.join(__dirname, ".env");
  if (!fs.existsSync(envPath)) return;
  for (const raw of fs.readFileSync(envPath, "utf8").split("\n")) {
    const line = raw.trim();
    if (!line || line.startsWith("#")) continue;
    const eq = line.indexOf("=");
    if (eq === -1) continue;
    const key = line.slice(0, eq).trim();
    let val = line.slice(eq + 1).trim();
    if (
      (val.startsWith('"') && val.endsWith('"')) ||
      (val.startsWith("'") && val.endsWith("'"))
    ) {
      val = val.slice(1, -1);
    }
    if (!(key in process.env)) process.env[key] = val;
  }
})();

const TOKEN = process.env.TELEGRAM_BOT_TOKEN;
const CHAT_ID = process.env.TELEGRAM_CHAT_ID;
const PORT = process.env.PORT || 3000;
const SECRET = process.env.WEBHOOK_SECRET || ""; // optional shared secret

if (!TOKEN || !CHAT_ID) {
  console.error(
    "[bridge] Missing TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID. Copy .env.example to .env and fill it in."
  );
  process.exit(1);
}

// ---- Helpers -----------------------------------------------------------
function readBody(req) {
  return new Promise((resolve) => {
    let data = "";
    req.on("data", (c) => {
      data += c;
      if (data.length > 1e6) req.destroy(); // 1MB guard
    });
    req.on("end", () => {
      if (!data) return resolve({});
      try {
        return resolve(JSON.parse(data));
      } catch (e) {
        // fall back to form-encoded
        const obj = {};
        for (const pair of data.split("&")) {
          const [k, v] = pair.split("=");
          if (k) obj[decodeURIComponent(k)] = decodeURIComponent(v || "");
        }
        return resolve(obj);
      }
    });
  });
}

function pick(obj, keys) {
  for (const k of keys) {
    if (obj && obj[k] != null && String(obj[k]).trim() !== "") return obj[k];
  }
  return "";
}

// Build a lead notification from a (flexible) GHL payload.
function formatLead(p) {
  const c = p.contact || p.customData || p;
  const first = pick(c, ["first_name", "firstName", "first", "contact_first_name"]);
  const last = pick(c, ["last_name", "lastName", "last", "contact_last_name"]);
  const full =
    pick(c, ["full_name", "fullName", "name", "contact_name"]) ||
    [first, last].filter(Boolean).join(" ");
  const phone = pick(c, ["phone", "phone_number", "contact_phone"]);
  const email = pick(c, ["email", "email_address", "contact_email"]);
  const source = pick(c, ["source", "lead_source", "utm_source"]);
  const rows = [
    "<b>📥 New lead — Xclusive Senior</b>",
    full ? "👤 " + escapeHtml(full) : "",
    phone ? "📞 " + escapeHtml(phone) : "",
    email ? "✉️ " + escapeHtml(email) : "",
    source ? "🔗 " + escapeHtml(source) : "",
  ].filter(Boolean);
  return rows.join("\n");
}

function formatAudit(result) {
  const { counts, lines, total } = result;
  const head =
    `<b>🌐 Bilingual SMS Audit</b>\n` +
    `Total: <b>${total}</b> · ✅ ${counts.bilingual} · ⚠️ ${counts.english} English-only · 📋 ${counts.spanish} · ❔ ${counts.unclear}`;
  const body = lines
    .map((l) => {
      const preview = l.text.replace(/\s+/g, " ").slice(0, 120);
      return `${l.label} — <b>${escapeHtml(l.name)}</b>\n<i>${escapeHtml(preview)}</i>`;
    })
    .join("\n\n");
  const flagged = lines.filter((l) => l.kind === "english");
  const footer = flagged.length
    ? `\n\n⚠️ <b>${flagged.length} message(s) need a Spanish version.</b>`
    : "\n\n🎉 Every message has both languages.";
  return head + "\n\n" + body + footer;
}

function checkSecret(req, url) {
  if (!SECRET) return true;
  const provided =
    url.searchParams.get("key") || req.headers["x-webhook-secret"] || "";
  return provided === SECRET;
}

function json(res, code, obj) {
  res.writeHead(code, { "Content-Type": "application/json" });
  res.end(JSON.stringify(obj));
}

// ---- Server ------------------------------------------------------------
const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  const route = url.pathname.replace(/\/+$/, "") || "/";

  try {
    if (req.method === "GET" && route === "/") {
      return json(res, 200, {
        ok: true,
        service: "ghl-telegram-bridge",
        endpoints: ["/ghl/lead", "/ghl/notify", "/ghl/audit"],
      });
    }

    if (req.method !== "POST") {
      return json(res, 405, { ok: false, error: "Use POST" });
    }
    if (!checkSecret(req, url)) {
      return json(res, 401, { ok: false, error: "Bad or missing secret" });
    }

    const body = await readBody(req);

    if (route === "/ghl/lead") {
      const text = formatLead(body);
      await sendMessage(TOKEN, CHAT_ID, text);
      return json(res, 200, { ok: true, sent: "lead" });
    }

    if (route === "/ghl/notify") {
      const text = pick(body, ["text", "message", "msg"]) || "(empty notification)";
      await sendMessage(TOKEN, CHAT_ID, escapeHtml(text));
      return json(res, 200, { ok: true, sent: "notify" });
    }

    if (route === "/ghl/audit") {
      const messages = body.messages || body.items || [];
      if (!Array.isArray(messages) || messages.length === 0) {
        return json(res, 400, {
          ok: false,
          error: 'Send JSON like { "messages": [{ "name": "Welcome", "text": "..." }] }',
        });
      }
      const result = audit(messages);
      await sendMessage(TOKEN, CHAT_ID, formatAudit(result));
      return json(res, 200, { ok: true, sent: "audit", counts: result.counts });
    }

    return json(res, 404, { ok: false, error: "Unknown route: " + route });
  } catch (err) {
    console.error("[bridge] error:", err.message);
    return json(res, 500, { ok: false, error: err.message });
  }
});

server.listen(PORT, () => {
  console.log(`[bridge] listening on port ${PORT}`);
  console.log(`[bridge] POST /ghl/lead   -> lead notification`);
  console.log(`[bridge] POST /ghl/notify -> free-text message`);
  console.log(`[bridge] POST /ghl/audit  -> bilingual SMS audit`);
});
