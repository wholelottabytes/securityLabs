/* eslint-disable no-unused-vars */
const Service = require('./Service');

// Получить все сообщения
const messagesGET = (pool) => new Promise(
  async (resolve, reject) => {
    try {
      const result = await pool.query('SELECT * FROM messages');
      resolve(Service.successResponse({
        messages: result.rows,
      }));
    } catch (e) {
      reject(Service.rejectResponse(
        e.message || 'Database error',
        e.status || 500,
      ));
    }
  },
);

// Удалить сообщение
const messagesIdDELETE = (pool, { id }) => new Promise(
  async (resolve, reject) => {
    try {
      await pool.query('DELETE FROM messages WHERE id = $1', [id]);
      resolve(Service.successResponse({ id }));
    } catch (e) {
      reject(Service.rejectResponse(
        e.message || 'Database error',
        e.status || 500,
      ));
    }
  },
);

// Обновить сообщение
const messagesIdPUT = (pool, { id, messagesIdPutRequest }) => new Promise(
  async (resolve, reject) => {
    try {
      const { msg, fromUserId, toUserId } = messagesIdPutRequest;
      await pool.query('UPDATE messages SET content = $1, sender_id = $2, receiver_id = $3 WHERE id = $4', [msg, fromUserId, toUserId, id]);
      resolve(Service.successResponse({
        id,
        updatedMessage: msg,
        sender_id: fromUserId,
        receiver_id: toUserId,
      }));
    } catch (e) {
      reject(Service.rejectResponse(
        e.message || 'Database error',
        e.status || 500,
      ));
    }
  },
);

// Отправить сообщение
const messagesPOST = (pool, { messagesPostRequest }) => new Promise(
  async (resolve, reject) => {
    try {
      const { msg, fromUserId, toUserId } = messagesPostRequest;
      await pool.query(
        'INSERT INTO messages (content, sender_id, receiver_id) VALUES ($1, $2, $3)', 
        [msg, fromUserId, toUserId]
      );
      resolve(Service.successResponse({
        msg,
        fromUserId,
        toUserId,
      }));
    } catch (e) {
      reject(Service.rejectResponse(
        e.message || 'Database error',
        e.status || 500,
      ));
    }
  },
);

// Удалить пользователя
const usersIdDELETE = (pool, { id }) => new Promise(
  async (resolve, reject) => {
    try {
      await pool.query('DELETE FROM users WHERE id = $1', [id]);
      resolve(Service.successResponse({ id }));
    } catch (e) {
      reject(Service.rejectResponse(
        e.message || 'Database error',
        e.status || 500,
      ));
    }
  },
);

// Добавить пользователя
const usersPOST = (pool, { usersPostRequest }) => new Promise(
  async (resolve, reject) => {
    try {
      const { username, password } = usersPostRequest;
      await pool.query('INSERT INTO users (username, password) VALUES ($1, $2)', [username, password]);
      resolve(Service.successResponse({
        username,
      }));
    } catch (e) {
      reject(Service.rejectResponse(
        e.message || 'Database error',
        e.status || 500,
      ));
    }
  },
);

module.exports = {
  messagesGET,
  messagesIdDELETE,
  messagesIdPUT,
  messagesPOST,
  usersIdDELETE,
  usersPOST,
};
