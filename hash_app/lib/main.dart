import 'dart:ui';

import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Предполагая, что проект называется flutter_application_chat
import 'dart:developer' as developer;
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/messages_screen.dart';
import 'utils/app_config.dart'; // Для URL сервера

void main() {
  // Добавляем глобальный обработчик ошибок Flutter
  FlutterError.onError = (FlutterErrorDetails details) {
    print('Flutter Error: ${details.exception}');
    print('Stack trace: ${details.stack}');
    developer.log('Flutter Error', error: details.exception, stackTrace: details.stack);
  };

  // Обработчик ошибок Dart (неперехваченных)
  PlatformDispatcher.instance.onError = (error, stack) {
    print('Dart Error: $error');
    print('Stack trace: $stack');
    developer.log('Dart Error (unhandled)', error: error, stackTrace: stack);
    return true; // true означает, что ошибка обработана
  };

  // Инициализация сервисов, если это необходимо до запуска приложения
  // Например, инициализация HashLibrary может быть частью AuthService
  // или выполнена здесь асинхронно.

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Попробуем инициализировать AuthService (и HashLibrary внутри него) здесь
    // Это простой способ, для более сложных случаев рассмотрите FutureBuilder или SplashScreen
    final authService = AuthService(); // Создание экземпляра для инициализации HashLibrary

    return MaterialApp(
      title: 'Flutter Chat App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/login', // Начальный экран - логин
      routes: {
        '/login': (context) => LoginScreen(authService: authService),
        '/register': (context) => RegistrationScreen(authService: authService),
        // MessagesScreen будет принимать userId и username после успешного логина
      },
      // Можно добавить onGenerateRoute для передачи аргументов в MessagesScreen
      onGenerateRoute: (settings) {
        if (settings.name == '/messages') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null && args.containsKey('userId') && args.containsKey('username')) {
            return MaterialPageRoute(
              builder: (context) {
                return MessagesScreen(
                  authService: authService, // Передаем authService
                  currentUserId: args['userId'] as int,
                  currentUsername: args['username'] as String,
                );
              },
            );
          }
        }
        // Обработка других маршрутов или возврат к домашнему, если аргументы неверны
        return MaterialPageRoute(builder: (context) => LoginScreen(authService: authService));
      },
      home: LoginScreen(authService: authService), // Fallback home
      debugShowCheckedModeBanner: false,
    );
  }
}