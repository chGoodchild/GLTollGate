

Generate a key pair:
```
GLTollGate/nostr$ ./seedphrase_generator.sh 
Your BIP39 mnemonic is: awesome idea nephew extend few since despair pony matter grocery scorpion relief
Your Nostr secret key (private key) is:  nsec1fejgdxt3dujrkk8pv52mzf4apanh0yyxt3zpt3yl5l3f3ywpu5yqeknu63
Your Nostr public key is:  npub1qv2cvh3mamem05kdv2hfz2ur3jqjmcqw9kkr8qc2yn77uzrset95cq45t53

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



https://pypi.org/project/nostr-sdk/

https://github.com/nostr-dev-kit/ndk/tree/master/ndk/src/relay

https://pypi.org/project/nostr/

