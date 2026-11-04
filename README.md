# HF780 Diary

A one-week diary site for the Nike diary study. The page is hosted on GitHub Pages. Entries and photos are stored in Supabase, where only you can see them.

## What is in this folder

| File | What it does |
|---|---|
| `index.html` | The whole site (welcome, calendar, day pages, entry form, confirmation). |
| `config.js` | The only file you edit. Holds your two Supabase values. |
| `assets/logo.png` | The logo in the header. Replace it with the corrected logo file when you have it. |
| `supabase/schema.sql` | Sets up the database and photo storage. You run it once. |

Until `config.js` is filled in, the site runs in **preview mode**. You can click through every screen, and entries stay on that device only. Open `index.html` in a browser to try it.

## Step 1: Make the Supabase project (about 10 minutes)

1. Go to supabase.com and sign up (free).
2. Click **New project**. Name it `hf780-diary`, set a database password (save it somewhere), and pick the region closest to you. Wait about 2 minutes for it to finish.
3. In the left menu open **SQL Editor** and click **New query**.
4. Open `supabase/schema.sql`, copy everything, paste it into the editor, and click **Run**. You should see "Success. No rows returned."

## Step 2: Copy two values into `config.js`

1. In Supabase, open **Project Settings** (gear icon) and then **API Keys**. If you see **Data API** instead, the URL is there.
2. Copy the **Project URL** (it looks like `https://abcdxyz.supabase.co`).
3. Copy the **anon** key, or the **publishable** key if that is the name you see. Never use the `service_role` or `secret` key.
4. Open `config.js` and paste them in place of `YOUR_SUPABASE_URL` and `YOUR_SUPABASE_ANON_KEY`. Keep the quotes.

The anon or publishable key is meant to be public. It is safe in a public repository because the database only allows the three actions the site needs.

## Step 3: Put it on GitHub Pages

1. On github.com click **New repository**. Name it `hf780-diary` and set it to **Public** (free GitHub Pages needs this).
2. Click **uploading an existing file**, drag in everything from this folder (`index.html`, `config.js`, the `assets` folder, and the `supabase` folder), and click **Commit changes**.
3. Open **Settings > Pages**. Under **Build and deployment**, choose **Deploy from a branch**, pick `main` and `/ (root)`, and click **Save**.
4. After about a minute your link appears at the top of that page. It looks like `https://yourusername.github.io/hf780-diary/`. That is the link you give the participant.

## Step 4: Test it before you give out the link

1. Open your link, type your own name and a code, and open your diary.
2. Day 1 starts **the day after you sign up**. To test today, open Supabase **Table Editor > diaries** and change `start_date` to today's date.
3. Add a photo entry and a note, then check that they show up in Supabase (see below).
4. When you are done testing, delete your test diary: in **Table Editor > diaries**, delete your test row. Its entries delete with it.

## How the participant gets in

- First visit: they type their first name and make up a code (4 or more characters). That creates the diary.
- Any later visit, on any device: same name and same code.
- The code is stored scrambled (hashed), so you cannot read it either. If they forget it, delete their row in `diaries` and have them start again, or ask them to re-enter their entries.

## Where you see the participant's entries

In Supabase:

- **Table Editor > entries** lists every entry with its day, type, note, and time.
- **Table Editor > diaries** shows the participant and the `start_date`.
- To see everything in one list with photo links, go to **SQL Editor**, replace `YOUR_PROJECT_URL`, and run:

```sql
select d.name, e.study_day, e.kind, e.note, e.created_at,
       'YOUR_PROJECT_URL/storage/v1/object/public/diary-media/' || e.media_path as media_link
from entries e join diaries d on d.id = e.diary_id
order by e.created_at;
```

Click **Download CSV** above the results to save it. Photos and voice memos are under **Storage > diary-media**, and each `media_link` opens one directly.

## Good to know

- **Dates:** The calendar locks future days. A day opens at midnight in the participant's own time zone.
- **Missed days:** The participant can still open a past day and add an entry.
- **Voice memos:** The site records in the browser (the participant is asked for microphone permission once) or accepts an audio file. If recording does not work on their phone, they can use the upload button.
- **Photo size:** Photos are shrunk before upload so the free plan lasts. Files over 15 MB are rejected.
- **Free plan limits:** Supabase may pause a free project after a week with no activity. Open the dashboard before the study starts to make sure it is awake.
- **Privacy:** Ask for a first name only. After the class is over, delete the project or the rows (Project Settings > General > Delete project). If you would rather stop new uploads earlier, in **Storage > Policies** delete the policy named `diary anon upload`.
- **Only a small number of diaries can be created** (5 by default, set by `max_diaries` in `schema.sql`). This stops strangers from creating diaries if they find the link.
- **Study dates:** Day 1 to Day 6 follow the `start_date` in the `diaries` table, so you can move the week by editing that one date.
