"use strict";
/* Helper: prints the chat IDs your bot can see.
 *
 * 1) Add your bot to the group/chat and send any message there.
 * 2) Run:  TELEGRAM_BOT_TOKEN=123:ABC node get-chat-id.js
 *    (or put the token in .env and run: node get-chat-id.js)
 */
const fs = require("fs");
const path = require("path");
const https = require("https");

(function loadEnv() {
  const envPath = path.join(__dirname, ".env");
  if (!fs.existsSync(envPath)) return;
  for (const raw of fs.readFileSync(envPath, "utf8").split("\n")) {
    const line = raw.trim();
    if (!line || line.startsWith("#")) continue;
    const eq = line.indexOf("=");
    if (eq === -1) continue;
    const key = line.slice(0, eq).trim();
    let val = line.slice(eq + 1).trim().replace(/^["']|["']$/g, "");
    if (!(key in process.env)) process.env[key] = val;
  }
})();

const TOKEN = process.env.TELEGRAM_BOT_TOKEN;
if (!TOKEN) {
  console.error("Set TELEGRAM_BOT_TOKEN (env or .env) first.");
  process.exit(1);
}

https
  .get(`https://api.telegram.org/bot${TOKEN}/getUpdates`, (res) => {
    let data = "";
    res.on("data", (c) => (data += c));
    res.on("end", () => {
      let json;
      try {
        json = JSON.parse(data);
      } catch (e) {
        console.error("Unexpected response:", data);
        return;
      }
      if (!json.ok) {
        console.error("Telegram error:", json.description);
        return;
      }
      const seen = new Map();
      for (const u of json.result || []) {
        const chat = (u.message || u.channel_post || u.my_chat_member || {}).chat;
        if (chat) seen.set(chat.id, chat.title || chat.username || chat.first_name || "(private)");
      }
      if (seen.size === 0) {
        console.log(
          "No chats found yet. Add the bot to your group, send a message there, then re-run."
        );
        return;
      }
      console.log("Chats your bot can post to:\n");
      for (const [id, name] of seen) {
        console.log(`  chat_id: ${id}   —   ${name}`);
      }
      console.log("\nPut the right one in .env as TELEGRAM_CHAT_ID.");
    });
  })
  .on("error", (e) => console.error("Request failed:", e.message));
