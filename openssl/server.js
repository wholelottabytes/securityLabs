const https = require('https');
const fs = require('fs');

const options = {
  key: fs.readFileSync('server.key'),
  cert: fs.readFileSync('server.crt'),
};

https.createServer(options, (req, res) => {
  	res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
	res.end('Всё работает!');
}).listen(443, () => {
  console.log('HTTPS сервер запущен на https://server.example.local');
});
