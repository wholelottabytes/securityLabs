#include "hash_lib.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#ifdef _WIN32
#include <windows.h>
#include <wincrypt.h>
#else
#include <unistd.h>
#include <fcntl.h>
#endif

// Версия библиотеки
static const char* LIBRARY_VERSION = "1.0.0";

// Простая реализация SHA-256 (для демонстрации)
// В продакшене используйте проверенные библиотеки типа OpenSSL

// SHA-256 константы
static const uint32_t K[64] = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
};

// Вспомогательные функции для SHA-256
static uint32_t rotr(uint32_t x, int n) {
    return (x >> n) | (x << (32 - n));
}

static uint32_t ch(uint32_t x, uint32_t y, uint32_t z) {
    return (x & y) ^ (~x & z);
}

static uint32_t maj(uint32_t x, uint32_t y, uint32_t z) {
    return (x & y) ^ (x & z) ^ (y & z);
}

static uint32_t sig0(uint32_t x) {
    return rotr(x, 2) ^ rotr(x, 13) ^ rotr(x, 22);
}

static uint32_t sig1(uint32_t x) {
    return rotr(x, 6) ^ rotr(x, 11) ^ rotr(x, 25);
}

static uint32_t theta0(uint32_t x) {
    return rotr(x, 7) ^ rotr(x, 18) ^ (x >> 3);
}

static uint32_t theta1(uint32_t x) {
    return rotr(x, 17) ^ rotr(x, 19) ^ (x >> 10);
}

// Простая SHA-256 реализация
static void sha256_hash(const unsigned char* data, size_t len, unsigned char* hash) {
    uint32_t h[8] = {
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
    };
    
    size_t msg_len = len;
    size_t padded_len = ((len + 8) / 64 + 1) * 64;
    unsigned char* padded = calloc(padded_len, 1);
    
    memcpy(padded, data, len);
    padded[len] = 0x80;
    
    // Добавляем длину в конец
    for (int i = 0; i < 8; i++) {
        padded[padded_len - 1 - i] = (msg_len * 8) >> (i * 8);
    }
    
    // Обрабатываем блоки по 512 бит
    for (size_t chunk = 0; chunk < padded_len; chunk += 64) {
        uint32_t w[64];
        
        // Копируем блок в w[0..15]
        for (int i = 0; i < 16; i++) {
            w[i] = (padded[chunk + i * 4] << 24) |
                   (padded[chunk + i * 4 + 1] << 16) |
                   (padded[chunk + i * 4 + 2] << 8) |
                   padded[chunk + i * 4 + 3];
        }
        
        // Расширяем w[16..63]
        for (int i = 16; i < 64; i++) {
            w[i] = theta1(w[i-2]) + w[i-7] + theta0(w[i-15]) + w[i-16];
        }
        
        uint32_t a = h[0], b = h[1], c = h[2], d = h[3];
        uint32_t e = h[4], f = h[5], g = h[6], h_temp = h[7];
        
        for (int i = 0; i < 64; i++) {
            uint32_t t1 = h_temp + sig1(e) + ch(e, f, g) + K[i] + w[i];
            uint32_t t2 = sig0(a) + maj(a, b, c);
            
            h_temp = g;
            g = f;
            f = e;
            e = d + t1;
            d = c;
            c = b;
            b = a;
            a = t1 + t2;
        }
        
        h[0] += a; h[1] += b; h[2] += c; h[3] += d;
        h[4] += e; h[5] += f; h[6] += g; h[7] += h_temp;
    }
    
    // Конвертируем результат в байты
    for (int i = 0; i < 8; i++) {
        hash[i * 4] = h[i] >> 24;
        hash[i * 4 + 1] = h[i] >> 16;
        hash[i * 4 + 2] = h[i] >> 8;
        hash[i * 4 + 3] = h[i];
    }
    
    free(padded);
}

// Основная функция хеширования пароля с солью
int hash_password_sha256(const char* password, const char* salt, HashResult* result) {
    if (!password || !salt || !result) {
        return HASH_ERROR;
    }
    
    size_t pwd_len = strlen(password);
    size_t salt_len = strlen(salt);
    size_t combined_len = pwd_len + salt_len;
    
    char* combined = malloc(combined_len + 1);
    if (!combined) {
        return HASH_ERROR;
    }
    
    // Комбинируем пароль и соль
    strcpy(combined, password);
    strcat(combined, salt);
    
    unsigned char hash_bytes[32];
    sha256_hash((unsigned char*)combined, combined_len, hash_bytes);
    
    // Конвертируем в hex строку
    for (int i = 0; i < 32; i++) {
        sprintf(&result->hash[i * 2], "%02x", hash_bytes[i]);
    }
    result->hash[64] = '\0';
    result->length = 64;
    
    // Очищаем чувствительные данные
    clear_sensitive_data(combined, combined_len);
    free(combined);
    
    return HASH_SUCCESS;
}

// Альтернативная функция хеширования (более сложная)
int hash_password_bcrypt_style(const char* password, const char* salt, HashResult* result) {
    if (!password || !salt || !result) {
        return HASH_ERROR;
    }
    
    // Для простоты делаем несколько итераций SHA-256
    HashResult temp_result;
    int iterations = 1000;  // В реальном bcrypt это 2^cost
    
    strcpy(temp_result.hash, password);
    strcat(temp_result.hash, salt);
    
    for (int i = 0; i < iterations; i++) {
        unsigned char hash_bytes[32];
        sha256_hash((unsigned char*)temp_result.hash, strlen(temp_result.hash), hash_bytes);
        
        for (int j = 0; j < 32; j++) {
            sprintf(&temp_result.hash[j * 2], "%02x", hash_bytes[j]);
        }
        temp_result.hash[64] = '\0';
    }
    
    strcpy(result->hash, temp_result.hash);
    result->length = 64;
    
    return HASH_SUCCESS;
}

// Верификация пароля
int verify_password(const char* password, const char* salt, const char* expected_hash) {
    if (!password || !salt || !expected_hash) {
        return HASH_ERROR;
    }
    
    HashResult result;
    if (hash_password_sha256(password, salt, &result) != HASH_SUCCESS) {
        return HASH_ERROR;
    }
    
    return (strcmp(result.hash, expected_hash) == 0) ? HASH_SUCCESS : HASH_ERROR;
}

// Генерация соли
int generate_salt(char* salt_buffer, size_t buffer_size) {
    if (!salt_buffer || buffer_size < 17) {  // Минимум 16 символов + null terminator
        return HASH_ERROR;
    }
    
    const char charset[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    
#ifdef _WIN32
    HCRYPTPROV hProvider;
    if (!CryptAcquireContext(&hProvider, NULL, NULL, PROV_RSA_FULL, CRYPT_VERIFYCONTEXT)) {
        // Fallback to time-based
        srand((unsigned int)time(NULL));
        for (size_t i = 0; i < buffer_size - 1; i++) {
            salt_buffer[i] = charset[rand() % (sizeof(charset) - 1)];
        }
    } else {
        BYTE random_bytes[16];
        if (CryptGenRandom(hProvider, sizeof(random_bytes), random_bytes)) {
            for (size_t i = 0; i < buffer_size - 1 && i < sizeof(random_bytes); i++) {
                salt_buffer[i] = charset[random_bytes[i] % (sizeof(charset) - 1)];
            }
        }
        CryptReleaseContext(hProvider, 0);
    }
#else
    int fd = open("/dev/urandom", O_RDONLY);
    if (fd >= 0) {
        unsigned char random_bytes[16];
        if (read(fd, random_bytes, sizeof(random_bytes)) == sizeof(random_bytes)) {
            for (size_t i = 0; i < buffer_size - 1 && i < sizeof(random_bytes); i++) {
                salt_buffer[i] = charset[random_bytes[i] % (sizeof(charset) - 1)];
            }
        }
        close(fd);
    } else {
        // Fallback to time-based
        srand((unsigned int)time(NULL));
        for (size_t i = 0; i < buffer_size - 1; i++) {
            salt_buffer[i] = charset[rand() % (sizeof(charset) - 1)];
        }
    }
#endif
    
    salt_buffer[buffer_size - 1] = '\0';
    return HASH_SUCCESS;
}

// Очистка чувствительных данных
void clear_sensitive_data(void* data, size_t size) {
    if (data) {
        volatile unsigned char* p = (volatile unsigned char*)data;
        for (size_t i = 0; i < size; i++) {
            p[i] = 0;
        }
    }
}

// Получение версии библиотеки
const char* get_library_version(void) {
    return LIBRARY_VERSION;
}