// Static file server for Battleship. All game state lives in Supabase;
// this process is stateless and holds no games.
const http = require('http');
const fs = require('fs');
const path = require('path');

try {
  process.loadEnvFile(path.join(__dirname, '.env'));
} catch {
  // no .env file; fall back to the ambient environment
}

const PORT = process.env.PORT || 3100;
const { SUPABASE_URL, SUPABASE_ANON_KEY } = process.env;

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.error('Missing SUPABASE_URL / SUPABASE_ANON_KEY. Copy .env.example to .env and fill it in.');
  process.exit(1);
}

const MIME = { '.html': 'text/html', '.css': 'text/css', '.js': 'text/javascript' };

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);

  // The anon key is public by design (RLS is the boundary), but keeping it
  // here instead of in the HTML means the client is not edited per-deploy.
  if (url.pathname === '/config') {
    res.writeHead(200, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' });
    res.end(JSON.stringify({ url: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY }));
    return;
  }

  const file = url.pathname === '/' ? 'index.html' : path.basename(url.pathname);
  fs.readFile(path.join(__dirname, 'public', file), (err, data) => {
    if (err) {
      res.writeHead(404).end('not found');
      return;
    }
    res.writeHead(200, { 'Content-Type': MIME[path.extname(file)] || 'application/octet-stream' });
    res.end(data);
  });
});

server.listen(PORT, () => console.log(`battleship on http://localhost:${PORT}`));
