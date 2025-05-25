const config = require('./config');
const logger = require('./logger');
const ExpressServer = require('./expressServer');
const { Pool } = require('pg');
const service = require('./services/Service');

// Подключение к базе данных
const pool = new Pool({
  host: process.env.DATABASE_HOST,
  port: process.env.DATABASE_PORT || 5432,
  user: process.env.DATABASE_USER,
  password: process.env.DATABASE_PASSWORD,
  database: process.env.DATABASE_NAME,
});

// Функция для создания таблиц
const createTables = async () => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(100) NOT NULL,
        password VARCHAR(100) NOT NULL
      );
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS messages (
        id SERIAL PRIMARY KEY,
        content TEXT NOT NULL,
        sender_id INTEGER REFERENCES users(id),
        receiver_id INTEGER REFERENCES users(id)
      );
    `);

    console.log('Tables created successfully!');
  } catch (e) {
    console.error('Error creating tables:', e);
    throw e;
  }
};

const launchServer = async () => {
  try {
    // Сначала создаем таблицы
    await createTables();

    // Запуск сервера
    this.expressServer = new ExpressServer(config.URL_PORT, config.OPENAPI_YAML);
    this.expressServer.launch();
    logger.info('Express server running');
    
    // Пример вызова сервиса с использованием pool
    const messages = await service.messagesGET(pool); // Пример вызова
    console.log(messages);
  } catch (error) {
    logger.error('Express Server failure', error.message);
    await this.close();
  }
};

launchServer().catch(e => logger.error(e));
