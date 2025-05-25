CC = gcc
CFLAGS = -fPIC -Wall -O2
LDFLAGS = -shared
TARGET = libhash.so
SRCS = hash.c sha256.c

all:
	$(CC) $(CFLAGS) $(SRCS) -o $(TARGET) $(LDFLAGS)

clean:
	rm -f $(TARGET)
