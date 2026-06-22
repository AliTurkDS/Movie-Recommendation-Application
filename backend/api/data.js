import { put, get } from '@vercel/blob';

// Every backup is stored as backups/<key>.json, where <key> is the sha256
// the Flutter app derives from email+password. Same key in = same file out.
const PREFIX = 'backups/';

// The key is always a 64-char hex sha256 — validating it blocks path
// traversal and junk requests.
const KEY_RE = /^[a-f0-9]{64}$/;

// Read the raw request body. Vercel may or may not have pre-parsed it for this
// raw ESM function, so cover every case rather than relying on req.body.
async function readBody(req) {
  if (typeof req.body === 'string') return req.body;
  if (req.body && typeof req.body === 'object') return JSON.stringify(req.body);
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  return Buffer.concat(chunks).toString('utf8');
}

export default async function handler(req, res) {
  // CORS — the Flutter web build calls this from a different origin.
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(204).end();

  const id = req.query.id;
  if (!id || !KEY_RE.test(id)) {
    return res.status(400).json({ error: 'invalid id' });
  }
  const pathname = `${PREFIX}${id}.json`;

  try {
    if (req.method === 'GET') {
      // get() authenticates with BLOB_READ_WRITE_TOKEN, so it can read the
      // private blob directly (returns null when the key doesn't exist).
      const result = await get(pathname, { access: 'private', useCache: false });
      if (!result) return res.status(404).json({ error: 'not found' });
      const text = await new Response(result.stream).text();
      res.setHeader('Content-Type', 'application/json');
      return res.status(200).send(text);
    }

    if (req.method === 'POST') {
      const body = await readBody(req);
      if (!body) return res.status(400).json({ error: 'empty body' });
      await put(pathname, body, {
        access: 'private',
        addRandomSuffix: false,
        allowOverwrite: true,
        contentType: 'application/json',
      });
      return res.status(200).json({ ok: true });
    }

    return res.status(405).json({ error: 'method not allowed' });
  } catch (e) {
    // Log the real error server-side; don't leak internals to the client.
    console.error('data handler error:', e);
    return res.status(500).json({ error: 'server error' });
  }
}
