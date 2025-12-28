import { createServer } from 'node:http';

const server = createServer((req, res) => {
  if (req.method === 'OPTIONS') {
    res.writeHead(204); // No content needed for preflight success
    res.end();
    return;
  }
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('Hello World!\n');
});

server.listen(3000, '0.0.0.0', () => {
  console.log('Listening on 0.0.0.0:3000');
});