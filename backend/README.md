# CineSwipe Sync Backend

A ~40-line Vercel serverless function that stores each user's backup as a JSON
file in Vercel Blob storage. There is **no authentication** — the Flutter app
hashes the user's email + password into an opaque key (`sha256(email:password)`)
and that key is the filename. Same email + password ⇒ same file ⇒ same data on
any device.

## Endpoint

`/api/data?id=<64-char-sha256>`

- `GET`  → returns that user's backup JSON, or `404` if none exists.
- `POST` → body is the backup JSON; overwrites any existing backup for that key.

## One-time deploy

From inside this `backend/` folder:

```bash
npm install -g vercel        # if you don't have the CLI
npm install                  # installs @vercel/blob
vercel login                 # browser login
vercel link                  # create / link a Vercel project
```

Then, in the **Vercel dashboard** for this project:

1. Go to **Storage → Create → Blob** and create a Blob store.
2. **Connect** it to this project. Vercel auto-adds the
   `BLOB_READ_WRITE_TOKEN` environment variable — that's all the function needs.

Finally deploy:

```bash
vercel deploy --prod
```

Copy the production URL it prints (e.g. `https://cineswipe-sync.vercel.app`)
and paste it into the Flutter app at
`lib/core/constants.dart` → `SyncConfig.baseUrl`.

## Local test (optional)

```bash
vercel dev
# POST a backup
curl -X POST "http://localhost:3000/api/data?id=<64 hex chars>" \
  -H "Content-Type: application/json" -d '{"hello":"world"}'
# GET it back
curl "http://localhost:3000/api/data?id=<same 64 hex chars>"
```
