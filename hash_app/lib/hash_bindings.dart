import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'dart:convert' show utf8; // Для Utf8.decode, если понадобится, но для String.fromCharCodes не нужен

// Структура для результата хеширования
base class HashResult extends Struct {
  @Array(65) // 64 символа + null terminator
  external Array<Uint8> hash;
  @Int32()
  external int length;
}

// Определяем сигнатуры C функций
typedef HashPasswordNative = Int32 Function(
    Pointer<Utf8> password,
    Pointer<Utf8> salt,
    Pointer<HashResult> result);

typedef GenerateSaltNative = Int32 Function(
    Pointer<Utf8> saltBuffer, Int32 bufferSize);

typedef VerifyPasswordNative = Int32 Function(Pointer<Utf8> password,
    Pointer<Utf8> salt, Pointer<Utf8> expectedHash);

typedef GetLibraryVersionNative = Pointer<Utf8> Function();

// Dart сигнатуры
typedef HashPasswordDart = int Function(Pointer<Utf8> password,
    Pointer<Utf8> salt, Pointer<HashResult> result);

typedef GenerateSaltDart = int Function(
    Pointer<Utf8> saltBuffer, int bufferSize);

typedef VerifyPasswordDart = int Function(Pointer<Utf8> password,
    Pointer<Utf8> salt, Pointer<Utf8> expectedHash);

typedef GetLibraryVersionDart = Pointer<Utf8> Function();

class HashLibrary {
  static const int HASH_SUCCESS = 0;
  static const int HASH_ERROR = -1;
  // static const int HASH_BUFFER_SIZE = 64; // Не используется напрямую в Dart коде здесь

  late DynamicLibrary _lib;
  late HashPasswordDart _hashPassword;
  late GenerateSaltDart _generateSalt;
  late VerifyPasswordDart _verifyPassword;
  late GetLibraryVersionDart _getLibraryVersion;

  HashLibrary() {
    print('HashLibrary: Starting initialization...');
    _loadLibrary(); // Этот метод может выбросить исключение
    print('HashLibrary: Library loaded, binding functions...');
    _bindFunctions(); // Этот метод также может выбросить исключение
    // Вывод версии здесь может быть преждевременным, если getLibraryVersion использует _lib,
    // но оставим как в твоем примере.
    print('HashLibrary: Initialization completed successfully! Version: ${getLibraryVersion()}');
  }

  void _loadLibrary() {
    String libraryPath;
    List<String> attemptPaths = [];

    print('HashLibrary: Detecting platform...');
    if (Platform.isAndroid) {
      libraryPath = 'android/app/src/main/jniLibs/arm64-v8a/libhash_lib.so';
    } else if (Platform.isLinux) {
      libraryPath = 'lib/native_libs/linux/libhash_lib.so';
    } else if (Platform.isWindows) {
      libraryPath = 'lib/native_libs/windows/libhash_lib.dll';
    } else if (Platform.isMacOS) {
      libraryPath = 'lib/native_libs/macos/libhash_lib.dylib';
    } else {
      throw UnsupportedError('Unsupported platform for HashLibrary');
    }
    attemptPaths.add(libraryPath);
    print('HashLibrary: Primary library path: $libraryPath');

    final file = File(libraryPath);
    print('HashLibrary: Library file exists at primary path: ${file.existsSync()}');

    try {
      _lib = DynamicLibrary.open('libhash_lib.so');
      print('HashLibrary: Successfully loaded library from primary path!');
    } catch (e) {
      print('HashLibrary: Failed to load from primary path ($libraryPath): $e');
      throw Exception('Failed to load hash library from $libraryPath. Error: $e. Attempted paths: $attemptPaths');
    }
  }


  void _bindFunctions() {
    try {
      print('HashLibrary: Binding hash_password_sha256...');
      _hashPassword = _lib
          .lookup<NativeFunction<HashPasswordNative>>('hash_password_sha256')
          .asFunction();
      print('HashLibrary: hash_password_sha256 bound successfully');

      print('HashLibrary: Binding generate_salt...');
      _generateSalt = _lib
          .lookup<NativeFunction<GenerateSaltNative>>('generate_salt')
          .asFunction();
      print('HashLibrary: generate_salt bound successfully');

      print('HashLibrary: Binding verify_password...');
      _verifyPassword = _lib
          .lookup<NativeFunction<VerifyPasswordNative>>('verify_password')
          .asFunction();
      print('HashLibrary: verify_password bound successfully');

      print('HashLibrary: Binding get_library_version...');
      _getLibraryVersion = _lib
          .lookup<NativeFunction<GetLibraryVersionNative>>('get_library_version')
          .asFunction();
      print('HashLibrary: get_library_version bound successfully');
    } catch (e) {
      print('HashLibrary: Error binding functions: $e');
      rethrow;
    }
  }

  String generateSalt() {
    // Добавим проверку, что _lib инициализирована, хотя в твоей структуре
    // конструктор выбросит исключение раньше, если _loadLibrary или _bindFunctions не удастся.
    // if (_lib == null) throw Exception("HashLibrary not properly initialized for generateSalt");

    print('HashLibrary: generateSalt() called');
    final saltBuffer = calloc<Uint8>(17); // 16 символов + null terminator
    try {
      print('HashLibrary: Calling native generate_salt...');
      final result = _generateSalt(saltBuffer.cast<Utf8>(), 17);
      print('HashLibrary: generate_salt returned: $result');

      if (result == HASH_SUCCESS) {
        final saltString = saltBuffer.cast<Utf8>().toDartString();
        print('HashLibrary: Generated salt: $saltString');
        return saltString;
      } else {
        throw Exception('Failed to generate salt, error code: $result');
      }
    } catch (e) {
      print('HashLibrary: Exception in generateSalt: $e');
      rethrow;
    } finally {
      calloc.free(saltBuffer);
    }
  }

  String hashPassword(String password, String salt) {
    // if (_lib == null) throw Exception("HashLibrary not properly initialized for hashPassword");

    final passwordPtr = password.toNativeUtf8();
    final saltPtr = salt.toNativeUtf8();
    final resultPtr = calloc<HashResult>();

    try {
      final status = _hashPassword(passwordPtr, saltPtr, resultPtr);
      if (status == HASH_SUCCESS) {
        final Array<Uint8> hashArray = resultPtr.ref.hash;
        final int length = resultPtr.ref.length;

        // Создаем List<int> из Array<Uint8> до указанной длины.
        // Это исправленный способ, который не использует .dimensions
        final bytes = <int>[];
        for (int i = 0; i < length; i++) {
          // Убедимся, что не выходим за пределы массива (обычно 64 для hash + 1 для \0)
          // Размер @Array(65) уже это учитывает.
          if (i < 65) { // Максимальный индекс 64 для массива размером 65
            bytes.add(hashArray[i]);
          } else {
            // Этого не должно произойти, если length корректна и не больше 64-65.
            break;
          }
        }

        // Предполагаем, что C-функция заполняет 'hash' кодами символов для строки (например, hex)
        // и 'length' - это длина этой строки.
        // Если хеш представляет собой последовательность байт, которые могут не быть валидными UTF-8 символами,
        // то String.fromCharCodes может быть не лучшим выбором.
        // В этом случае лучше использовать hex-кодирование:
        // return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
        // Однако, если сервер ожидает именно строку, полученную через fromCharCodes, оставляем так.
        // Твой оригинальный код использовал String.fromCharCodes, так что я его сохраняю.
        return String.fromCharCodes(bytes);
      } else {
        throw Exception('Failed to hash password, native function returned error code: $status');
      }
    } finally {
      calloc.free(passwordPtr);
      calloc.free(saltPtr);
      calloc.free(resultPtr);
    }
  }

  bool verifyPassword(String password, String salt, String expectedHash) {
    // if (_lib == null) throw Exception("HashLibrary not properly initialized for verifyPassword");

    print('HashLibrary: verifyPassword() called');
    final passwordPtr = password.toNativeUtf8();
    final saltPtr = salt.toNativeUtf8();
    final expectedHashPtr = expectedHash.toNativeUtf8();
    try {
      print('HashLibrary: Calling native verify_password...');
      final result = _verifyPassword(passwordPtr, saltPtr, expectedHashPtr);
      print('HashLibrary: verify_password returned: $result');
      return result == HASH_SUCCESS;
    } catch (e) {
      print('HashLibrary: Exception in verifyPassword: $e');
      rethrow;
    } finally {
      calloc.free(passwordPtr);
      calloc.free(saltPtr);
      calloc.free(expectedHashPtr);
    }
  }

  String getLibraryVersion() {
    // if (_lib == null) throw Exception("HashLibrary not properly initialized for getLibraryVersion");
    print('HashLibrary: getLibraryVersion() called');
    try {
      final versionPtr = _getLibraryVersion();
      final version = versionPtr.toDartString();
      print('HashLibrary: Library version: $version');
      return version;
    } catch (e) {
      print('HashLibrary: Exception in getLibraryVersion: $e');
      rethrow;
    }
  }
}