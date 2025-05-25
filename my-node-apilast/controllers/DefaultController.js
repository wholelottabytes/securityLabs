/**
 * The DefaultController file is a very simple one, which does not need to be changed manually,
 * unless there's a case where business logic routes the request to an entity which is not
 * the service.
 * The heavy lifting of the Controller item is done in Request.js - that is where request
 * parameters are extracted and sent to the service, and where response is handled.
 */

const Controller = require('./Controller');
const service = require('../services/DefaultService');
const messagesGET = async (request, response) => {
  await Controller.handleRequest(request, response, service.messagesGET);
};

const messagesIdDELETE = async (request, response) => {
  await Controller.handleRequest(request, response, service.messagesIdDELETE);
};

const messagesIdPUT = async (request, response) => {
  await Controller.handleRequest(request, response, service.messagesIdPUT);
};

const messagesPOST = async (request, response) => {
  await Controller.handleRequest(request, response, service.messagesPOST);
};

const usersIdDELETE = async (request, response) => {
  await Controller.handleRequest(request, response, service.usersIdDELETE);
};

const usersPOST = async (request, response) => {
  await Controller.handleRequest(request, response, service.usersPOST);
};


module.exports = {
  messagesGET,
  messagesIdDELETE,
  messagesIdPUT,
  messagesPOST,
  usersIdDELETE,
  usersPOST,
};
