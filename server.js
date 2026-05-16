const http = require('http');
const https = require('https');

const PORT = process.env.PORT || 3000;
let TUNNEL_URL = process.env.TUNNEL_URL || '';

// Simple in-memory store for tunnel URL
let currentTunnelUrl = TUNNEL_URL;

function fetchFromPrometheus(path, res) {
  if (!currentTunnelUrl) {
    res.writeHead(503, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
    res.end(JSON.stringify({ error: 'Tunnel URL not configured. POST /update-tunnel with {"url":"..."}' }));
    return;
  }

  const target = currentTunnelUrl + path;
  const client = target.startsWith('https') ? https : http;

  client.get(target, (pres) => {
    let data = '';
    pres.on('data', chunk => data += chunk);
    pres.on('end', () => {
      res.writeHead(pres.statusCode, {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': '*'
      });
      res.end(data);
    });
  }).on('error', (e) => {
    res.writeHead(502, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
    res.end(JSON.stringify({ error: e.message, tunnelUrl: currentTunnelUrl }));
  });
}

const server = http.createServer((req, res) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': '*'
    });
    res.end();
    return;
  }

  // Update tunnel URL endpoint
  if (req.method === 'POST' && req.url === '/update-tunnel') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const { url, secret } = JSON.parse(body);
        if (secret !== process.env.UPDATE_SECRET) {
          res.writeHead(401, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
          res.end(JSON.stringify({ error: 'Invalid secret' }));
          return;
        }
        currentTunnelUrl = url.replace(/\/$/, '');
        console.log('Tunnel URL updated to:', currentTunnelUrl);
        res.writeHead(200, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
        res.end(JSON.stringify({ success: true, tunnelUrl: currentTunnelUrl }));
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
        res.end(JSON.stringify({ error: 'Invalid JSON' }));
      }
    });
    return;
  }

  // Status endpoint
  if (req.url === '/status') {
    res.writeHead(200, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
    res.end(JSON.stringify({
      status: 'running',
      tunnelUrl: currentTunnelUrl || 'not configured',
      uptime: process.uptime()
    }));
    return;
  }

  // Health check
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('OK');
    return;
  }

  // Proxy all other requests to Prometheus
  fetchFromPrometheus(req.url, res);
});

server.listen(PORT, () => {
  console.log(`IT Command Center Backend running on port ${PORT}`);
  console.log(`Tunnel URL: ${currentTunnelUrl || 'not set - use POST /update-tunnel'}`);
});
