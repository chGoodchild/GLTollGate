

Generate a key pair:
```
GLTollGate/nostr$ ./seedphrase_generator.sh

up to date, audited 46 packages in 4s

2 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
Your BIP39 mnemonic is: predict urban defy angry abstract slogan exist april such final model safe
Your Nostr secret key (private key) is:  nsec3b5930ebd09ae5739f2c8bff1fe176955906ea2e413649c77762d4635678b4c8
Your Nostr public key is:  npub024048fc5653e919d4ea924becb393cacff1c04b7450293175a8044f7fcd942b4b


```

Translate to mnemonic:
```
GLTollGate/nostr$ ./key_to_mnemonic.sh nsec3b5930ebd09ae5739f2c8bff1fe176955906ea2e413649c77762d4635678b4c8

up to date, audited 46 packages in 1s

2 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
Your BIP39 mnemonic is: deputy sister depend patrol purity right lake multiply yellow yellow frozen click motor insect ribbon chat endorse desert suffer potato cube detail spring brown
```

Translate back:
```
GLTollGate/nostr$ ./mnemonic_to_key.sh "deputy sister depend patrol purity right lake multiply yellow yellow frozen click motor insect ribbon chat endorse desert suffer potato cube detail spring brown"

up to date, audited 46 packages in 893ms

2 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
Your Nsec (private key) is: nsec3b5930ebd09ae5739f2c8bff1fe176955906ea2e413649c77762d4635678b4c8
Your Npub (public key) is: npub024048fc5653e919d4ea924becb393cacff1c04b7450293175a8044f7fcd942b4b

```

