CC=gcc
CFLAGS=-I/usr/local/ssl/include -I/home/pachai/nostr_client_relay/src/nostril -g -Wall
LDFLAGS=-L/usr/local/ssl/lib64 -lwallycore -lssl -lcrypto -lsecp256k1 -Wl,-rpath,/usr/local/ssl/lib64

# Source files
SRC=generate_npub.c \
    /home/pachai/nostr_client_relay/src/nostril/nostri.c \
    /home/pachai/nostr_client_relay/src/nostril/aes.c \
    /home/pachai/nostr_client_relay/src/nostril/base64.c \
    /home/pachai/nostr_client_relay/src/nostril/sha256.c

# Object files
OBJ=$(SRC:.c=.o)

# Executable
EXEC=generate_npub

all: $(EXEC)

$(EXEC): $(OBJ)
	$(CC) -o $@ $^ $(LDFLAGS)  # Ensure this line begins with a tab

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<  # Ensure this line begins with a tab

clean:
	rm -f $(OBJ) $(EXEC)  # Ensure this line begins with a tab

.PHONY: all clean

