import '../hash_bindings.dart';
import 'api_service.dart';

class AuthService {
  late HashLibrary _hashLib; // Будет инициализирована в конструкторе
  final ApiService _apiService = ApiService();
  bool _isHashLibInitialized = false; // Флаг инициализации в AuthService

  // Данные текущего пользователя
  int? currentUserId;
  String? currentUsername;

  AuthService() {
    try {
      // Пытаемся создать экземпляр HashLibrary.
      // Если конструктор HashLibrary выбросит исключение (например, не сможет загрузить библиотеку),
      // то мы перейдем в блок catch.
      _hashLib = HashLibrary();

      // Если мы дошли до сюда, значит конструктор HashLibrary успешно отработал.
      // Это означает, что библиотека загружена и функции связаны.
      _isHashLibInitialized = true;
      print("AuthService: HashLibrary initialized successfully (constructor did not throw).");
      // Для дополнительной уверенности можно попробовать вызвать простой метод, например getLibraryVersion,
      // но он тоже может выбросить исключение, если что-то не так с привязками,
      // хотя конструктор HashLibrary уже должен был это проверить.
      // print("AuthService: HashLibrary Version: ${_hashLib.getLibraryVersion()}");

    } catch (e) {
      // Если во время new HashLibrary() произошло исключение.
      _isHashLibInitialized = false;
      print("AuthService: CRITICAL ERROR initializing HashLibrary: $e");
      // В этом состоянии _hashLib может быть не присвоен или быть в невалидном состоянии.
      // Флаг _isHashLibInitialized = false предотвратит его использование.
    }
  }

  // Геттер для проверки готовности библиотеки из других частей приложения
  bool get isHashLibraryReady => _isHashLibInitialized;

  String _hashPassword(String password, String usernameAsSalt) {
    if (!isHashLibraryReady) {
      // Это исключение будет поймано в вызывающих методах (register, login)
      throw Exception("Hash library is not initialized. Cannot hash password.");
    }
    // Теперь, если isHashLibraryReady == true, _hashLib точно инициализирован
    return _hashLib.hashPassword(password, usernameAsSalt);
  }

  Future<Map<String, dynamic>> register(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      // Можно вернуть Map с ошибкой, чтобы соответствовать другим возвратам
      return {'success': false, 'message': 'Имя пользователя и пароль не могут быть пустыми.'};
    }
    try {
      final hashedPassword = _hashPassword(password, username); // Может выбросить исключение, если !isHashLibraryReady
      final response = await _apiService.registerUser(username, hashedPassword);

      if (response.containsKey('id') && response.containsKey('username')) {
        return {'success': true, 'message': 'Пользователь создан!', 'data': response};
      } else {
        return {'success': false, 'message': 'Ошибка регистрации: неверный ответ от сервера.'};
      }
    } catch (e) {
      // Ловим исключения от _hashPassword или _apiService
      return {'success': false, 'message': 'Ошибка регистрации: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      return {'success': false, 'message': 'Имя пользователя и пароль не могут быть пустыми.'};
    }
    try {
      final hashedPassword = _hashPassword(password, username); // Может выбросить исключение, если !isHashLibraryReady
      final response = await _apiService.loginUser(username, hashedPassword);

      if (response.containsKey('id') && response.containsKey('username')) {
        currentUserId = response['id'] as int;
        currentUsername = response['username'] as String;
        return {'success': true, 'message': 'Успешный вход!', 'data': response};
      } else {
        return {'success': false, 'message': 'Ошибка входа: неверный ответ от сервера.'};
      }
    } catch (e) {
      // Ловим исключения от _hashPassword или _apiService
      return {'success': false, 'message': 'Ошибка входа: ${e.toString()}'};
    }
  }

  void logout() {
    currentUserId = null;
    currentUsername = null;
  }

  int? getLoggedInUserId() => currentUserId;
  String? getLoggedInUsername() => currentUsername;
}