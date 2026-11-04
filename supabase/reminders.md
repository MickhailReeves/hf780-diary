# Emails: 7 PM reminders and code reset

Two Edge Functions send email through Brevo:
- `send-reminders`: run every hour by the pg_cron job `diary-reminders`. It only acts at 7 PM Eastern, only on the six study days, and at most once per diary per day.
- `reset-code`: called by the "Forgot code?" screen. Emails a 6-digit code that works for 30 minutes (one request per 5 minutes, five tries).

Both read these secrets (Supabase > Edge Functions > Secrets):
- `BREVO_API_KEY`: a Brevo API key (v3).
- `SENDER_EMAIL`: the sender address you verified in Brevo.

Stop reminders: SQL Editor > `select cron.unschedule('diary-reminders');`
After the study, clear stored emails: `update public.diaries set email = null;`
