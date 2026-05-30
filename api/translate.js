// Vercel serverless function: translate KO/EN → ZH via Claude
// POST /api/translate  body: { text: "..." }
// Response: { zh: "...", detected: "ko" | "en" | "zh" }
//
// Required env var (Vercel project settings → Environment Variables):
//   ANTHROPIC_API_KEY = sk-ant-...

const SYSTEM_PROMPT = `You are a professional translator producing simplified Chinese (zh-CN) translations of heartfelt farewell messages.

Context: These are personal messages written by colleagues at Promega for Tao Cui, who has led Promega Beijing since the 1990s and is now departing. The Chinese-speaking audience in Beijing should read these in their native language and feel the same warmth the original author intended.

Style guidelines:
- Translate meaning, not word-by-word. Produce natural, native-sounding 简体中文.
- Preserve the emotional register: warm, sincere, sometimes informal, sometimes formal.
- Korean honorifics → render as appropriately respectful Chinese (using 您 where it fits, but not overdoing it).
- English casual/professional tone → render as 温暖而得体的中文.
- Keep length close to source. Do not pad with flowery additions.
- Preserve line breaks if present.

Names & terms to keep EXACTLY as written (do NOT translate):
- Tao Cui, Tao, Promega, Promega Beijing, PBK, Spring GMM, Madison Campus, ProCon Asia, PacAsia
- Personal names of contributors

Output format: ONLY the Chinese translation. No quotes, no labels, no preface, no explanation, no English in parentheses. Just the message in 简体中文, ready to display.`;

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'POST only' });

  const body = req.body || {};
  const text = typeof body.text === 'string' ? body.text.trim() : '';
  if (!text) return res.status(400).json({ error: 'text required' });
  if (text.length > 4000) return res.status(400).json({ error: 'text too long' });

  // Detect source language
  const hasHangul = /[ㄱ-힝]/.test(text);
  const hasHan = /[一-鿿]/.test(text);
  // Heuristic: if >40% of CJK-ish chars are Han and no Hangul → already Chinese
  const detected = hasHangul ? 'ko' : (hasHan && !hasHangul ? 'zh' : 'en');

  // Already Chinese — no translation needed
  if (detected === 'zh') {
    return res.status(200).json({ zh: text, detected });
  }

  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    console.error('ANTHROPIC_API_KEY not set');
    // Soft-fail: return empty translation so the client still saves the original
    return res.status(200).json({ zh: '', detected, error: 'server config missing' });
  }

  const sourceName = detected === 'ko' ? 'Korean' : 'English';
  const userPrompt = `Translate this ${sourceName} message into simplified Chinese (zh-CN), following all style guidelines. Return only the translation.\n\n---\n${text}\n---`;

  try {
    const r = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-5',
        max_tokens: 800,
        temperature: 0.4,
        system: SYSTEM_PROMPT,
        messages: [{ role: 'user', content: userPrompt }],
      }),
    });

    if (!r.ok) {
      const errText = await r.text().catch(() => '');
      console.error('Anthropic API error', r.status, errText);
      return res.status(200).json({ zh: '', detected, error: `upstream ${r.status}` });
    }
    const data = await r.json();
    let translation = (data.content && data.content[0] && data.content[0].text || '').trim();
    translation = translation.replace(/^["'""''](.*)["'""''‍]$/s, '$1').trim();

    return res.status(200).json({ zh: translation, detected });
  } catch (e) {
    console.error('translate exception', e);
    return res.status(200).json({ zh: '', detected, error: e && e.message || 'unknown' });
  }
};
