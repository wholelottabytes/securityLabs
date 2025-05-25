#ifndef HASH_H
#define HASH_H

#include <emscripten.h> // Добавляем заголовок

void EMSCRIPTEN_KEEPALIVE hash_password(const char* input, char* output);

#endif
