#include <stdint.h>
#include <string.h>
#include <stdio.h>

#define SALT "XyZ@123_"  // простая соль, можно передавать как параметр

void hash_password(const char *input, char *output)
{
    const char *salt = SALT;
    size_t len = strlen(input);
    size_t salt_len = strlen(salt);

    uint8_t hash[32] = {0};

    for (size_t i = 0; i < len; ++i) {
        hash[i % 32] ^= (input[i] ^ salt[i % salt_len]) + i;
        hash[i % 32] = (hash[i % 32] << 1) | (hash[i % 32] >> 7); // циклический сдвиг
    }

    // переводим в hex строку
    for (int i = 0; i < 32; ++i)
    {
        sprintf(output + (i * 2), "%02x", hash[i]);
    }
    output[64] = '\0';
}

