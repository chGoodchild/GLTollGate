const bip39 = require('bip39');
const bip32 = require('bip32');
const { ECPairFactory } = require('ecpair');
const ecc = require('tiny-secp256k1');
const { bech32 } = require('bech32'); // Use 'bech32' directly for Nostr

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
const privateKey = root.privateKey.toString('hex');

// Bech32 encode the private key
const words = bech32.toWords(Buffer.from(privateKey, 'hex'));
const bech32PrivateKey = bech32.encode('nsec', words);

// Get the public key using the ECPair
const keyPair = ECPair.fromPrivateKey(root.privateKey);
const publicKey = keyPair.publicKey.toString('hex');

// Bech32 encode the public key
const pubWords = bech32.toWords(Buffer.from(publicKey, 'hex'));
const bech32PublicKey = bech32.encode('npub', pubWords);

console.log("Your Nostr secret key (private key) is: ", bech32PrivateKey);
console.log("Your Nostr public key is: ", bech32PublicKey);

