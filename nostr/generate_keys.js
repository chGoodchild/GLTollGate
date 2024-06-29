const bip39 = require('bip39');
const bip32 = require('bip32');
const { ECPairFactory } = require('ecpair');
const ecc = require('tiny-secp256k1');
const bitcoin = require('bitcoinjs-lib');

// Use ECPairFactory to create an ECPair instance
const ECPair = ECPairFactory(ecc);

// Generate a BIP39 mnemonic
const mnemonic = bip39.generateMnemonic();
console.log("Your BIP39 mnemonic is:", mnemonic);

// Convert the mnemonic to a BIP32 seed
const seed = bip39.mnemonicToSeedSync(mnemonic);

// Create a BIP32 node from the seed
const root = bip32.fromSeed(seed);

// Get the private key in hexadecimal format
const privateKey = "nsec" + root.privateKey.toString('hex');

// Get the public key using the ECPair
const keyPair = ECPair.fromPrivateKey(root.privateKey);
const publicKey = "npub" + keyPair.publicKey.toString('hex');

console.log("Your Nostr secret key (private key) is: ", privateKey);
console.log("Your Nostr public key is: ", publicKey);

