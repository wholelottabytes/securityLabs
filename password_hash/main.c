#include <stdio.h>
#include <string.h>
#include <emscripten/emscripten.h>
#include "hash.h"

EMSCRIPTEN_KEEPALIVE
void hash_password_wrapper(const char *input, char *output)
{
    hash_password(input, output);
}
