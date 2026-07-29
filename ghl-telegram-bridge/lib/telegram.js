"use strict";
/* Minimal Telegram Bot API client (zero dependencies). */
const https = require("https");

function escapeHtml(s) {
  return String(s == null ? "" : s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

function apiCall(token, method, body) {
  return new Promise((resolve, reject) => {
    const payload = JSON.stringify(body);
    const req = https.request(
      {
        hostname: "api.telegram.org",
        path: `/bot${token}/${method}`,
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Content-Length": Buffer.byteLength(payload),
        },
      },
      (res) => {
        let data = "";
        res.on("data", (c) => (data += c));
        res.on("end", () => {
          let json;
          try {
            json = JSON.parse(data);
          } catch (e) {
            json = { ok: false, description: "Non-JSON response: " + data };
          }
          if (json && json.ok) resolve(json.result);
          else
            reject(
              new Error(
                "Telegram API error (" +
                  res.statusCode +
                  "): " +
                  (json && json.description ? json.description : data)
              )
            );
        });
      }
    );
    req.on("error", reject);
    req.write(payload);
    req.end();
  });
}

// Telegram messages cap at 4096 chars; split on line breaks to stay safe.
function chunk(text, max = 3800) {
  if (text.length <= max) return [text];
  const parts = [];
  let cur = "";
  for (const line of text.split("\n")) {
    if ((cur + "\n" + line).length > max) {
      if (cur) parts.push(cur);
      cur = line;
    } else {
      cur = cur ? cur + "\n" + line : line;
    }
  }
  if (cur) parts.push(cur);
  return parts;
}

async function sendMessage(token, chatId, text) {
  const results = [];
  for (const part of chunk(text)) {
    results.push(
      await apiCall(token, "sendMessage", {
        chat_id: chatId,
        text: part,
        parse_mode: "HTML",
        disable_web_page_preview: true,
      })
    );
  }
  return results;
}

module.exports = { sendMessage, escapeHtml, apiCall };
