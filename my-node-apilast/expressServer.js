// const { Middleware } = require('swagger-express-middleware');
const http = require('http');
const fs = require('fs');
const path = require('path');
const swaggerUI = require('swagger-ui-express');
const jsYaml = require('js-yaml');
const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const bodyParser = require('body-parser');
const { OpenApiValidator } = require('express-openapi-validator');
const logger = require('./logger');
const config = require('./config');
const pool = require('./db');

class ExpressServer {
  constructor(port, openApiYaml) {
    this.port = port;
    this.app = express();
    this.openApiPath = openApiYaml;
    try {
      this.schema = jsYaml.safeLoad(fs.readFileSync(openApiYaml));
    } catch (e) {
      logger.error('failed to start Express Server', e.message);
    }
    this.setupMiddleware();
  }

  setupMiddleware() {
    // this.setupAllowedMedia();
    this.app.use(cors());
    this.app.use(bodyParser.json({ limit: '14MB' }));
    this.app.use(express.json());
    this.app.use(express.urlencoded({ extended: false }));
    this.app.use(cookieParser());
    this.app.get('/hello', (req, res) => res.send(`Hello World. path: ${this.openApiPath}`));
    this.app.get('/openapi', (req, res) => res.sendFile((path.join(__dirname, 'api', 'openapi.yaml'))));
    this.app.use('/api-docs', swaggerUI.serve, swaggerUI.setup(this.schema));
    this.app.get('/login-redirect', (req, res) => {
      res.status(200);
      res.json(req.query);
    });
    this.app.get('/oauth2-redirect.html', (req, res) => {
      res.status(200);
      res.json(req.query);
    });
    // Логин: проверка username + password
    this.app.post('/login', async (req, res, next) => {
      try {
        const { username, password } = req.body;
        if (!username || !password) {
          return res.status(400).json({ message: 'Username and password are required' });
        }

        const user = await pool.query(
          'SELECT id, password FROM users WHERE username = $1',
          [username]
        );

        if (user.rows.length === 0) {
          return res.status(401).json({ message: 'Invalid credentials' });
        }

        // Тут предполагается, что пароль уже захеширован во Flutter и сравнивается напрямую
        const dbPassword = user.rows[0].password;
        if (password !== dbPassword) {
          return res.status(401).json({ message: 'Invalid credentials' });
        }

        res.status(200).json({ id: user.rows[0].id, username });
      } catch (err) {
        next(err);
      }
    });

    // Получить список всех пользователей
    this.app.get('/users', async (req, res, next) => {
      try {
        const result = await pool.query('SELECT id, username FROM users ORDER BY id ASC');
        res.status(200).json(result.rows);
      } catch (err) {
        next(err);
      }
    });

    // Зарегистрировать нового пользователя (username + хэш пароля)
    this.app.post('/user', async (req, res, next) => {
      try {
        const { username, password } = req.body;
        if (!username || !password) {
          return res.status(400).json({ message: 'Username and password are required' });
        }

        const existingUser = await pool.query('SELECT id FROM users WHERE username = $1', [username]);
        if (existingUser.rows.length > 0) {
          return res.status(409).json({ message: 'User already exists' });
        }

        const result = await pool.query(
          'INSERT INTO users (username, password) VALUES ($1, $2) RETURNING id', 
          [username, password]
        );
        res.status(201).json({ id: result.rows[0].id, username });
      } catch (err) {
        next(err);
      }
    });

    // Отправить сообщение от одного пользователя другому
    this.app.post('/messages', async (req, res, next) => {
      try {
        const { msg, fromUserId, toUserId } = req.body;
        if (!msg || !fromUserId || !toUserId) {
          return res.status(400).json({
            message: 'Missing required fields: msg, fromUserId, or toUserId',
          });
        }

        await pool.query(
          'INSERT INTO messages (content, sender_id, receiver_id) VALUES ($1, $2, $3)', 
          [msg, fromUserId, toUserId]
        );
        res.status(201).json({ msg, fromUserId, toUserId });
      } catch (err) {
        next(err);
      }
    });

    // Получить все сообщения, адресованные конкретному пользователю
    this.app.get('/messages/received/:userId', async (req, res, next) => {
      try {
        const { userId } = req.params;
        const result = await pool.query(
          `SELECT messages.*, u.username AS sender_username
          FROM messages 
          JOIN users u ON messages.sender_id = u.id
          WHERE receiver_id = $1 
          ORDER BY messages.id ASC`, 
          [userId]
        );
        res.status(200).json(result.rows);
      } catch (err) {
        next(err);
      }
    });
  }

  launch() {
    new OpenApiValidator({
      apiSpec: this.openApiPath,
      operationHandlers: path.join(__dirname),
      fileUploader: { dest: config.FILE_UPLOAD_PATH },
    }).install(this.app)
      .catch(e => console.log(e))
      .then(() => {
        // eslint-disable-next-line no-unused-vars
        this.app.use((err, req, res, next) => {
          // format errors
          res.status(err.status || 500).json({
            message: err.message || err,
            errors: err.errors || '',
          });
        });

        http.createServer(this.app).listen(this.port);
        console.log(`Listening on port ${this.port}`);
      });
  }


  async close() {
    if (this.server !== undefined) {
      await this.server.close();
      console.log(`Server on port ${this.port} shut down`);
    }
  }
}

module.exports = ExpressServer;
