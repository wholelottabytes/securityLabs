#ifndef HASH_LIB_H
#define HASH_LIB_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Константы для различных типов хеширования
#define HASH_SUCCESS 0
#define HASH_ERROR -1
#define HASH_BUFFER_SIZE 64

// Структура для результата хеширования
typedef struct {
    char hash[HASH_BUFFER_SIZE + 1];  // +1 для null terminator
    int length;
} HashResult;

// Основные функции для хеширования паролей
int hash_password_sha256(const char* password, const char* salt, HashResult* result);
int hash_password_bcrypt_style(const char* password, const char* salt, HashResult* result);
int verify_password(const char* password, const char* salt, const char* expected_hash);

// Утилитарные функции
int generate_salt(char* salt_buffer, size_t buffer_size);
void clear_sensitive_data(void* data, size_t size);

// Функция для получения версии библиотеки
const char* get_library_version(void);

#ifdef __cplusplus
}
#endif

#endif // HASH_LIB_H