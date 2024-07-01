Converting npub back and forth doesn't work yet:
```
GLTollGate/nostr$ ./npub_to_readable.sh npub024048fc5653e919d4ea924becb393cacff1c04b7450293175a8044f7fcd942b4b
Your BIP39 mnemonic is: across across disease protect direct mind father false episode grain top night yellow then column meat circle merry head ancient wave traffic expose hope

GLTollGate/nostr$ ./bip39_phrase_to_npub.sh "across across disease protect direct mind father false episode grain top night yellow then column meat circle merry head ancient wave traffic expose hope"
Your Npub (public key) is: npub024048fc5653e919d4ea924becb393cacff1c04b7450293175a8044f7fcd942b

```

The last two characters are missing:
```
npub024048fc5653e919d4ea924becb393cacff1c04b7450293175a8044f7fcd942b4b
npub024048fc5653e919d4ea924becb393cacff1c04b7450293175a8044f7fcd942b
```