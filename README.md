# Vardhman Sanskar Dham — App Hub

Three files:
- `index.html` — the volunteer-facing hub (categories → tiles → sub-tiles → link)
- `admin.html` — the tile configuration console (login required)
- `schema.sql` — the Supabase database + security rules

## 1. Create the Supabase project

1. Go to supabase.com → New project. Note the project's **Project URL** and **anon public key** (Project Settings → API).
2. Open the SQL Editor → New query → paste the entire contents of `schema.sql` → Run.
3. Go to Authentication → Providers → make sure **Email** is enabled (it is by default). Turn **off** "Confirm email" under Authentication → Settings if you don't want new sign-ups to need email verification (optional, up to you).

## 2. Wire up the two HTML files

In **both** `index.html` and `admin.html`, find this block near the bottom and fill in your real values:

```js
const SUPABASE_URL = "https://YOUR-PROJECT.supabase.co";
const SUPABASE_ANON_KEY = "YOUR-ANON-KEY";
```

The anon key is meant to be public (it's the same key that ends up in any static site's JS bundle) — the actual security is enforced by the Row Level Security policies in `schema.sql`: anyone can *read* tiles, but only allowlisted admins can *write*.

## 3. Create your first admin

The admin panel intentionally does **not** let anyone promote themselves to admin from the UI — that has to be a manual step so a compromised or mistaken sign-up can't grant itself write access.

1. Open `admin.html`, click **Create one**, sign up with your real email + a password.
2. In Supabase SQL Editor, run:
   ```sql
   insert into admins (id, email)
   select id, email from auth.users where email = 'you@example.com';
   ```
3. Reload `admin.html` and sign in. You're now an approved admin.

To add more admins later, have them sign up in `admin.html` first, then run the same `insert` with their email.

## 4. Host the files

Any static host works since there's no backend to run — Supabase is the backend:
- Netlify / Vercel: drag the folder in, or connect a GitHub repo.
- GitHub Pages: push to a repo, enable Pages.
- Or even an internal server / shared drive if `admin.html` and `index.html` can be opened via HTTPS (Supabase Auth requires HTTPS or `localhost`, not `file://`).

Share the `index.html` link with volunteers and keep `admin.html` for organizers only. Because writes are gated by the `admins` table (not by hiding the URL), it's fine if the admin link becomes known — a non-admin who opens it just can't save anything.

## 5. Using the admin console

- **Add top-level tile**: choose a category (existing or new — typed freeform, e.g. `Jivdaya`, `Balsanskaran`, `Games`, `Logistics`), a name, an icon, and either a URL (makes it a direct-link tile) or leave URL blank and use **Add sub-tile** afterward to build a folder like "Kaun Banega Gyani" → Admin Control Room / Screen / Registration / Audience / Team.
- **Folders vs links**: a tile with no URL is a folder — tapping it in the volunteer hub drills into its children instead of navigating away. Nesting is unlimited, so a sub-tile can itself contain further sub-tiles if you ever need that.
- **Icons**: pick from the grid (curated common icons) or type any valid name from [lucide.dev/icons](https://lucide.dev/icons) into the text field — the preview grid highlights it if it's one of the curated set, but any valid Lucide name works.
- **Reordering**: use the up/down arrows on each tile; they only reorder among siblings (same category or same parent folder).
- **Deleting a folder deletes everything inside it** (cascading) — the console warns you with a count before confirming.

## Known limitations worth knowing about

- No drag-and-drop reordering — only up/down buttons. Fine for a few dozen tiles per level; tedious for hundreds.
- No audit log of who changed what. `updated_at` is tracked per tile, but not who touched it.
- No image/logo upload — icons are Lucide's icon set only, not custom app logos. If you want each app's actual logo instead of a generic icon, that's a bigger change (image storage + upload UI in the admin console) — flag it if you want that built out.
- The volunteer hub (`index.html`) opens links in a new tab. If any of your apps need to open in the same tab/frame instead, that's a one-line change (`target="_blank"` → remove it) in `index.html`.
