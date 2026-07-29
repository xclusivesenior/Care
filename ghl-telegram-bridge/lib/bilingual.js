"use strict";
/* Local English/Spanish detection heuristic. Same logic as the Chrome bar,
 * reused server-side so the bridge can audit SMS text and report results. */

const SPANISH_CHARS = /[¿¡ñáéíóúü]/i;
const SPANISH_WORDS =
  /\b(hola|gracias|por favor|usted|su cita|cita|cuidado|salud|paciente|enfermera|para|porque|ll[aá]menos|responda|mensaje|atenci[oó]n|bienvenid[oa]|confirmar|confirme|cancelar|recordatorio|hoy|ma[nñ]ana|fecha|hora|equipo|nuestr[oa]|ayuda|informaci[oó]n|servicios?)\b/i;
const ENGLISH_WORDS =
  /\b(the|you|your|please|reply|appointment|care|health|patient|nurse|reminder|today|tomorrow|confirm|cancel|message|welcome|team|our|help|thank you|thanks|stop|info|date|time|services?)\b/i;

function countMatches(text, regex) {
  const g = new RegExp(
    regex.source,
    regex.flags.includes("g") ? regex.flags : regex.flags + "g"
  );
  const m = text.match(g);
  return m ? m.length : 0;
}

function detect(text) {
  const t = (text || "").trim();
  const spanishScore =
    (SPANISH_CHARS.test(t) ? 2 : 0) + countMatches(t, SPANISH_WORDS);
  const englishScore = countMatches(t, ENGLISH_WORDS);
  return {
    hasSpanish: spanishScore >= 2,
    hasEnglish: englishScore >= 2,
    spanishScore,
    englishScore,
    length: t.length,
  };
}

function classify(text) {
  const d = detect(text);
  if (d.hasEnglish && d.hasSpanish) return { kind: "bilingual", label: "✅ Bilingual" };
  if (d.hasSpanish && !d.hasEnglish) return { kind: "spanish", label: "📋 Spanish only" };
  if (d.hasEnglish && !d.hasSpanish) return { kind: "english", label: "⚠️ English only" };
  return { kind: "unclear", label: "❔ Unclear / too short" };
}

/* messages: [{ name?, text }] -> { summary, lines[], counts } */
function audit(messages) {
  const counts = { bilingual: 0, english: 0, spanish: 0, unclear: 0 };
  const lines = [];
  (messages || []).forEach((m, i) => {
    const text = typeof m === "string" ? m : m.text || "";
    const name = (typeof m === "object" && m.name) || `Message ${i + 1}`;
    const c = classify(text);
    counts[c.kind]++;
    lines.push({ name, label: c.label, kind: c.kind, text });
  });
  return {
    counts,
    lines,
    total: lines.length,
  };
}

module.exports = { detect, classify, audit };
