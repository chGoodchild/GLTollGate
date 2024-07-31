CC=gcc
CFLAGS=-I/usr/local/ssl/include -g -Wall
LDFLAGS=-L/usr/local/ssl/lib64 -lwallycore -lssl -lcrypto -Wl,-rpath,/usr/local/ssl/lib64

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

