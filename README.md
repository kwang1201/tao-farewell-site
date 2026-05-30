# Tao Farewell — Promega Beijing

A single-page web app for colleagues to share photos and messages with Tao Cui,
plus a slideshow "Present" mode for the event.

**Live:** https://kwang1201.github.io/tao-farewell-site/

## Stack

- Single static HTML (no build step)
- [@supabase/supabase-js](https://supabase.com/docs/reference/javascript) via CDN
- Supabase Postgres + Storage (project shared with PBK20 events DB)
- Hosted on GitHub Pages

## Setup

See [SETUP.md](../SETUP.md) in the working folder for the SQL schema and
deployment guide. The source-of-truth HTML is `Tao farewell message v3.html`
in the working folder — this `site/` copy is what gets published.

## Sync from working folder

```powershell
Copy-Item "..\Tao farewell message v3.html" index.html
git add index.html
git commit -m "Sync from working folder"
git push
```
