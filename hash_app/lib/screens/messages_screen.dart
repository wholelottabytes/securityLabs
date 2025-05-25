import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart'; // Для выхода из системы
import '../models/user_model.dart';
import '../models/message_model.dart';

class MessagesScreen extends StatefulWidget {
  final AuthService authService;
  final int currentUserId;
  final String currentUsername;

  const MessagesScreen({
    super.key,
    required this.authService,
    required this.currentUserId,
    required this.currentUsername,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final ApiService _apiService = ApiService();
  List<User> _users = [];
  List<Message> _receivedMessages = [];
  bool _isLoadingUsers = false;
  bool _isLoadingMessages = false;
  User? _selectedUserForSending;
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchReceivedMessages();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final users = await _apiService.getAllUsers();
      // Исключаем текущего пользователя из списка для отправки сообщений
      setState(() {
        _users = users.where((user) => user.id != widget.currentUserId).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки пользователей: $e')),
      );
    } finally {
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _fetchReceivedMessages() async {
    setState(() => _isLoadingMessages = true);
    try {
      final messages = await _apiService.getReceivedMessages(widget.currentUserId);
      setState(() => _receivedMessages = messages);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки сообщений: $e')),
      );
    } finally {
      setState(() => _isLoadingMessages = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_selectedUserForSending == null || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите пользователя и введите сообщение.')),
      );
      return;
    }
    try {
      await _apiService.sendMessage(
        _messageController.text,
        widget.currentUserId,
        _selectedUserForSending!.id,
      );
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сообщение отправлено!')),
      );
      // Можно добавить обновление списка полученных сообщений, если это необходимо
      // или если отправленные сообщения тоже должны где-то отображаться.
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отправки сообщения: $e')),
      );
    }
  }

  void _logout() {
    widget.authService.logout();
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
  }


  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Сообщения (${widget.currentUsername})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Секция отправки сообщения
            const Text('Отправить сообщение:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_isLoadingUsers) const Center(child: CircularProgressIndicator())
            else DropdownButtonFormField<User>(
              decoration: const InputDecoration(labelText: 'Выберите пользователя'),
              value: _selectedUserForSending,
              items: _users.map((User user) {
                return DropdownMenuItem<User>(
                  value: user,
                  child: Text(user.username),
                );
              }).toList(),
              onChanged: (User? newValue) {
                setState(() {
                  _selectedUserForSending = newValue;
                });
              },
              hint: const Text('Кому'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Ваше сообщение',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _sendMessage,
              child: const Text('Отправить'),
            ),
            const Divider(height: 32, thickness: 2),

            // Секция полученных сообщений
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Полученные сообщения:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Обновить сообщения',
                  onPressed: _fetchReceivedMessages,
                ),
              ],
            ),
            if (_isLoadingMessages) const Center(child: CircularProgressIndicator())
            else if (_receivedMessages.isEmpty) const Text('Нет полученных сообщений.')
            else Expanded(
                child: ListView.builder(
                  itemCount: _receivedMessages.length,
                  itemBuilder: (context, index) {
                    final message = _receivedMessages[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        title: Text(message.content),
                        subtitle: Text('От: ${message.senderUsername ?? 'Неизвестный отправитель (ID: ${message.senderId})'}'),
                        // Можно добавить дату/время, если сервер их отдает
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}