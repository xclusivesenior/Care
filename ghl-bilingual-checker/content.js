/* GHL Bilingual SMS Checker
 * Injects a small bar into the page. While you are logged into GoHighLevel,
 * click "Scan page" to find SMS / message text and flag whether each message
 * is bilingual (English + Spanish) or English-only. No data leaves your browser.
 */
(function () {
  "use strict";
  if (window.__ghlbcLoaded) return;
  window.__ghlbcLoaded = true;

  // ---- Language detection ------------------------------------------------
  // Heuristic, fully local. Looks for Spanish-specific signals (diacritics,
  // inverted punctuation, common Spanish words) and English signals.
  const SPANISH_CHARS = /[¿¡ñáéíóúü]/i;
  const SPANISH_WORDS = /\b(hola|gracias|por favor|usted|su cita|cita|cuidado|salud|paciente|enfermera|para|porque|llámenos|llamenos|responda|mensaje|atención|atencion|bienvenido|bienvenida|confirmar|confirme|cancelar|recordatorio|hoy|mañana|manana|fecha|hora|equipo|nuestro|nuestra|le|ayuda|información|informacion|servicios?)\b/i;
  const ENGLISH_WORDS = /\b(the|you|your|please|reply|appointment|care|health|patient|nurse|reminder|today|tomorrow|confirm|cancel|message|welcome|team|our|help|thank you|thanks|stop|info|date|time|services?)\b/i;

  function countMatches(text, regex) {
    const g = new RegExp(regex.source, regex.flags.includes("g") ? regex.flags : regex.flags + "g");
    const m = text.match(g);
    return m ? m.length : 0;
  }

  function detect(text) {
    const t = (text || "").trim();
    const spanishScore =
      (SPANISH_CHARS.test(t) ? 2 : 0) + countMatches(t, SPANISH_WORDS);
    const englishScore = countMatches(t, ENGLISH_WORDS);
    const hasSpanish = spanishScore >= 2;
    const hasEnglish = englishScore >= 2;
    return { hasSpanish, hasEnglish, spanishScore, englishScore, length: t.length };
  }

  function classify(text) {
    const d = detect(text);
    if (d.hasEnglish && d.hasSpanish) return { kind: "ok", label: "✅ Bilingual", d };
    if (d.hasSpanish && !d.hasEnglish) return { kind: "info", label: "📋 Spanish only", d };
    if (d.hasEnglish && !d.hasSpanish) return { kind: "warn", label: "⚠️ English only", d };
    return { kind: "info", label: "❔ Unclear / too short", d };
  }

  // ---- Find candidate message text on the page ---------------------------
  function isVisible(el) {
    const r = el.getBoundingClientRect();
    const s = getComputedStyle(el);
    return r.width > 0 && r.height > 0 && s.visibility !== "hidden" && s.display !== "none";
  }

  function gatherCandidates() {
    const out = [];
    const seen = new Set();
    const push = (text, source) => {
      const t = (text || "").replace(/\s+\n/g, "\n").trim();
      if (t.length < 12) return;            // skip tiny labels
      if (t.length > 1600) return;          // skip page-sized blobs
      const key = t.slice(0, 200);
      if (seen.has(key)) return;
      seen.add(key);
      out.push({ text: t, source });
    };

    // Where GHL keeps editable SMS bodies: textareas + contenteditable fields.
    document.querySelectorAll("textarea").forEach((el) => {
      if (isVisible(el)) push(el.value, "textarea");
    });
    document.querySelectorAll('[contenteditable="true"], [contenteditable=""]').forEach((el) => {
      if (isVisible(el)) push(el.innerText, "editor");
    });

    // Rendered message bubbles / template previews (best-effort class match).
    const previewSel =
      '[class*="message"], [class*="sms"], [class*="bubble"], [class*="template"], [class*="preview"], [class*="conversation"]';
    document.querySelectorAll(previewSel).forEach((el) => {
      // only leaf-ish containers to avoid grabbing whole panels
      if (isVisible(el) && el.childElementCount <= 3) push(el.innerText, "preview");
    });

    return out;
  }

  // ---- UI ----------------------------------------------------------------
  const launch = document.createElement("button");
  launch.id = "ghlbc-launch";
  launch.textContent = "🌐 Bilingual SMS";
  document.body.appendChild(launch);

  const panel = document.createElement("div");
  panel.id = "ghlbc-panel";
  panel.innerHTML = `
    <div id="ghlbc-head">
      <span>Bilingual SMS Checker</span>
      <button id="ghlbc-close" title="Close">×</button>
    </div>
    <div id="ghlbc-actions">
      <button id="ghlbc-scan">Scan page</button>
      <button id="ghlbc-check" class="ghlbc-secondary">Check text below</button>
    </div>
    <div style="padding:8px 12px 0;">
      <textarea id="ghlbc-manual" placeholder="Paste one SMS message here to check it…"></textarea>
    </div>
    <div id="ghlbc-summary">Click <b>Scan page</b> while viewing your SMS workflows, templates, or conversations.</div>
    <div id="ghlbc-results"></div>
  `;
  document.body.appendChild(panel);

  const $ = (id) => panel.querySelector(id);
  launch.addEventListener("click", () => panel.classList.toggle("ghlbc-open"));
  $("#ghlbc-close").addEventListener("click", () => panel.classList.remove("ghlbc-open"));

  function render(items) {
    const results = $("#ghlbc-results");
    results.innerHTML = "";
    let ok = 0, warn = 0, info = 0;
    items.forEach((it) => {
      const c = classify(it.text);
      if (c.kind === "ok") ok++;
      else if (c.kind === "warn") warn++;
      else info++;
      const div = document.createElement("div");
      div.className = "ghlbc-item " + c.kind;
      const tag = document.createElement("span");
      tag.className = "ghlbc-tag " + c.kind;
      tag.textContent = c.label;
      const body = document.createElement("div");
      body.className = "ghlbc-text";
      body.textContent = it.text;
      const src = document.createElement("div");
      src.className = "ghlbc-muted";
      src.textContent = "source: " + it.source;
      div.appendChild(tag);
      div.appendChild(body);
      div.appendChild(src);
      results.appendChild(div);
    });
    $("#ghlbc-summary").innerHTML = items.length
      ? `Found <b>${items.length}</b> message(s): ` +
        `<b style="color:#166534">${ok} bilingual</b>, ` +
        `<b style="color:#991b1b">${warn} English-only</b>, ` +
        `<b style="color:#92400e">${info} other</b>.`
      : "No message text detected on this view. Open an SMS workflow step, a template, or a conversation, then scan again.";
  }

  $("#ghlbc-scan").addEventListener("click", () => render(gatherCandidates()));
  $("#ghlbc-check").addEventListener("click", () => {
    const t = $("#ghlbc-manual").value.trim();
    render(t ? [{ text: t, source: "pasted" }] : []);
  });
})();
