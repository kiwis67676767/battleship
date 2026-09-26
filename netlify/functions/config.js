// Serves the Supabase project URL and anon key to the browser.
// Netlify equivalent of the /config route in server.js (used for local dev).
export default () =>
  Response.json(
    { url: process.env.SUPABASE_URL, anonKey: process.env.SUPABASE_ANON_KEY },
    { headers: { 'Cache-Control': 'no-store' } }
  );

export const config = { path: '/config' };
