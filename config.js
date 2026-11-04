// Supabase connection for the HF780 diary. The anon key is meant to be public.
// (It can only call the three diary functions and upload files. It cannot read the tables.)
window.DIARY_CONFIG = {
  SUPABASE_URL: 'https://wcfixsjfhxpulxtszpja.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndjZml4c2pmaHhwdWx4dHN6cGphIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM4MTEzNTcsImV4cCI6MjEwOTM4NzM1N30.hiV8zMH85d518fRT68inbTfKkFCT4aijxRtqi7cePac'
};
