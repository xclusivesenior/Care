"use strict";
/* Zero-dependency smoke tests. Run with: npm test
 *
 * Covers the classifier and the server's routing/guards. The Telegram calls
 * themselves are not exercised - they need a real token and network - so the
 * audit test asserts the request is parsed and routed, not that it delivers.
 */
const assert = require("assert");
const http = require("http");
const { spawn } = require("child_process");
const { audit, classify, messageText } = require("./lib/bilingual");

let passed = 0;
function check(name, fn) {
  try {
    fn();
    console.log(`  ok    ${name}`);
    passed++;
  } catch (err) {
    console.error(`  FAIL  ${name}\n        ${err.message}`);
    process.exitCode = 1;
  }
}

console.log("classifier");

check("English-only is flagged", () => {
  assert.strictEqual(
    classify("Hi, please confirm your appointment reminder for tomorrow.").kind,
    "english"
  );
});

check("Spanish-only is detected", () => {
  assert.strictEqual(
    classify("Hola, gracias por su mensaje. Confirme su cita para mañana.").kind,
    "spanish"
  );
});

check("Bilingual is detected", () => {
  assert.strictEqual(
    classify("Please confirm your appointment. Por favor confirme su cita.").kind,
    "bilingual"
  );
});

check("empty text is unclear, not a false pass", () => {
  assert.strictEqual(classify("").kind, "unclear");
});

check("body/message/msg are read as the SMS text", () => {
  // GHL exports name this field inconsistently. Reading only `text` would
  // score a whole batch "unclear" and look like a finished audit.
  const sample = "Please confirm your appointment. Por favor confirme su cita.";
  for (const key of ["text", "body", "message", "msg", "content"]) {
    assert.strictEqual(messageText({ [key]: sample }), sample, `key: ${key}`);
  }
  assert.strictEqual(messageText("plain string"), "plain string");
  assert.strictEqual(messageText(null), "");
});

check("audit totals add up", () => {
  const r = audit([
    { name: "a", text: "Please confirm your appointment reminder today." },
    { name: "b", body: "Please confirm your appointment. Por favor confirme su cita." },
    { name: "c", text: "Hola, gracias por su mensaje, confirme su cita." },
  ]);
  assert.strictEqual(r.total, 3);
  const sum = Object.values(r.counts).reduce((a, b) => a + b, 0);
  assert.strictEqual(sum, 3, "counts must cover every message");
  assert.strictEqual(r.counts.bilingual, 1);
});

// ---- server routing -------------------------------------------------------
const PORT = process.env.TEST_PORT || 3199;

function request(method, path, body) {
  return new Promise((resolve, reject) => {
    const payload = body ? JSON.stringify(body) : null;
    const req = http.request(
      {
        host: "127.0.0.1",
        port: PORT,
        path,
        method,
        headers: payload
          ? { "Content-Type": "application/json", "Content-Length": Buffer.byteLength(payload) }
          : {},
      },
      (res) => {
        let data = "";
        res.on("data", (c) => (data += c));
        res.on("end", () => {
          try {
            resolve({ status: res.statusCode, json: JSON.parse(data) });
          } catch {
            resolve({ status: res.statusCode, json: {} });
          }
        });
      }
    );
    req.on("error", reject);
    if (payload) req.write(payload);
    req.end();
  });
}

async function waitForServer(attempts = 25) {
  for (let i = 0; i < attempts; i++) {
    try {
      await request("GET", "/");
      return true;
    } catch {
      await new Promise((r) => setTimeout(r, 200));
    }
  }
  return false;
}

(async function serverTests() {
  console.log("server");

  const child = spawn(process.execPath, ["server.js"], {
    cwd: __dirname,
    env: {
      ...process.env,
      TELEGRAM_BOT_TOKEN: "test:token",
      TELEGRAM_CHAT_ID: "-100123",
      PORT: String(PORT),
    },
    stdio: "ignore",
  });

  try {
    if (!(await waitForServer())) throw new Error(`server did not start on :${PORT}`);

    const health = await request("GET", "/");
    check("health endpoint lists the routes", () => {
      assert.strictEqual(health.status, 200);
      assert.strictEqual(health.json.ok, true);
      assert.deepStrictEqual(health.json.endpoints, ["/ghl/lead", "/ghl/notify", "/ghl/audit"]);
    });

    const empty = await request("POST", "/ghl/audit", { messages: [] });
    check("audit rejects an empty batch instead of reporting success", () => {
      assert.strictEqual(empty.status, 400);
      assert.strictEqual(empty.json.ok, false);
    });

    const missing = await request("POST", "/nope", {});
    check("unknown route returns 404", () => {
      assert.strictEqual(missing.status, 404);
    });
  } catch (err) {
    console.error(`  FAIL  server tests\n        ${err.message}`);
    process.exitCode = 1;
  } finally {
    child.kill();
  }

  console.log(`\n${passed} passed${process.exitCode ? " (with failures above)" : ""}`);
})();
