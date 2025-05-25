const express = require('express');
const path = require('path');
const app = express();

// Раздача статических файлов (hash.js и hash.wasm)
app.use(express.static(__dirname));

// Отдаём index.html по умолчанию
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.listen(8083, () => {
  console.log('Сервер запущен на http://localhost:8083');
});
