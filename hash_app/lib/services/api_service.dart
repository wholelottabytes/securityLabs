import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';

class ApiService {
  final String _baseUrl = AppConfig.apiBaseUrl;

  Future<Map<String, dynamic>> registerUser(String username, String hashedPassword) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/user'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': hashedPassword}),
    );
    print(hashedPassword);

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> loginUser(String username, String hashedPassword) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': hashedPassword}),
    );
    print(hashedPassword);

    return _handleResponse(response);

  }

  Future<List<User>> getAllUsers() async {
    final response = await http.get(Uri.parse('$_baseUrl/users'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => User.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load users: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> sendMessage(String message, int fromUserId, int toUserId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'msg': message,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to send message: ${response.statusCode} ${response.body}');
    }
    // Возвращать нечего, сервер отвечает 201 с телом сообщения
  }

  Future<List<Message>> getReceivedMessages(int userId) async {
    final response = await http.get(Uri.parse('$_baseUrl/messages/received/$userId'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Message.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load messages: ${response.statusCode} ${response.body}');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return body;
    } else {
      throw Exception('API Error: ${response.statusCode} - ${body['message'] ?? response.body}');
    }
  }
}