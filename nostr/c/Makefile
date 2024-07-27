CC=gcc
CFLAGS=-I/usr/local/include -I/usr/include/openssl -g -Wall
LDFLAGS=-L/usr/local/lib -lwallycore -lssl -lcrypto -Wl,-rpath,/usr/local/lib

SRC=generate_npub.c
OBJ=$(SRC:.c=.o)
EXEC=generate_npub

all: $(EXEC)

$(EXEC): $(OBJ)
	$(CC) -o $@ $^ $(LDFLAGS)

%.o: %.c
	$(CC) -c -o $@ $< $(CFLAGS)

clean:
	rm -f $(OBJ) $(EXEC)

.PHONY: all clean

