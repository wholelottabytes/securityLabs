class Message {
  final int id; // id сообщения из БД
  final String content;
  final int senderId;
  final int receiverId;
  final String? senderUsername; // Добавлено для отображения
  final String? createdAt; // Если сервер возвращает время создания

  Message({
    required this.id,
    required this.content,
    required this.senderId,
    required this.receiverId,
    this.senderUsername,
    this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int,
      content: json['content'] as String,
      senderId: json['sender_id'] as int,
      receiverId: json['receiver_id'] as int,
      senderUsername: json['sender_username'] as String?, // Убедись, что сервер это поле отдает
      createdAt: json['created_at'] as String?, // или `timestamp` или как называется поле
    );
  }
}