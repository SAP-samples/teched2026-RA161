#!/usr/bin/env node
// Decrypts the workshop IAS service binding shipped as
// credentials/ias-dev.json.enc into credentials/ias-dev.json.
//
// Usage:
//   node scripts/decrypt-credentials.cjs
//     Prompts for the passphrase announced at the session and writes
//     credentials/ias-dev.json (mode 600). Never prints binding values.
//
//   node scripts/decrypt-credentials.cjs --encrypt <ias-binding.json>
//     Facilitators: encrypts a downloaded IAS binding to
//     credentials/ias-dev.json.enc. Prompts for the passphrase twice.
//
// Format: AES-256-GCM, key derived with scrypt. The .enc file layout is
// magic(8) | salt(16) | iv(12) | auth tag(16) | ciphertext.

'use strict';

const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');

const MAGIC = Buffer.from('RA161ENC', 'ascii');
const REPO_ROOT = path.resolve(__dirname, '..');
const ENC_FILE = path.join(REPO_ROOT, 'credentials', 'ias-dev.json.enc');
const PLAIN_FILE = path.join(REPO_ROOT, 'credentials', 'ias-dev.json');

let pipedInput = null;
function nextPipedLine() {
  if (pipedInput === null) {
    pipedInput = fs.readFileSync(0, 'utf8').split('\n');
  }
  const line = pipedInput.shift();
  if (line === undefined) throw new Error('Ran out of piped input.');
  return line.replace(/\r$/u, '');
}

function promptHidden(question) {
  return new Promise((resolve, reject) => {
    const { stdin, stdout } = process;
    stdout.write(question);
    if (!stdin.isTTY) {
      stdout.write('\n');
      resolve(nextPipedLine());
      return;
    }
    stdin.setRawMode(true);
    stdin.resume();
    stdin.setEncoding('utf8');
    let value = '';
    const finish = (callback, result) => {
      stdin.setRawMode(false);
      stdin.pause();
      stdin.removeListener('data', onData);
      stdout.write('\n');
      callback(result);
    };
    const onData = (chunk) => {
      for (const ch of chunk) {
        if (ch === '\r' || ch === '\n') {
          finish(resolve, value);
          return;
        }
        if (ch === '\u0003') {
          finish(reject, new Error('Aborted.'));
          return;
        }
        if (ch === '\u007f' || ch === '\b') {
          value = value.slice(0, -1);
        } else {
          value += ch;
        }
      }
    };
    stdin.on('data', onData);
  });
}

function deriveKey(passphrase, salt) {
  return crypto.scryptSync(passphrase, salt, 32, { N: 16384, r: 8, p: 1 });
}

async function encrypt(inputPath) {
  const plaintext = fs.readFileSync(inputPath);
  JSON.parse(plaintext.toString('utf8')); // fail early on a non-JSON input
  const passphrase = await promptHidden('Passphrase for the workshop binding: ');
  if (!passphrase) throw new Error('A non-empty passphrase is required.');
  const confirmation = await promptHidden('Repeat the passphrase: ');
  if (passphrase !== confirmation) throw new Error('Passphrases do not match.');
  const salt = crypto.randomBytes(16);
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', deriveKey(passphrase, salt), iv);
  const ciphertext = Buffer.concat([cipher.update(plaintext), cipher.final()]);
  fs.mkdirSync(path.dirname(ENC_FILE), { recursive: true });
  fs.writeFileSync(ENC_FILE, Buffer.concat([MAGIC, salt, iv, cipher.getAuthTag(), ciphertext]));
  console.log(`Wrote ${path.relative(process.cwd(), ENC_FILE)}`);
}

async function decrypt() {
  if (!fs.existsSync(ENC_FILE)) {
    throw new Error(
      `Missing ${path.relative(process.cwd(), ENC_FILE)} — it is added shortly before the session; run git pull.`,
    );
  }
  const blob = fs.readFileSync(ENC_FILE);
  if (blob.length < 52 || !blob.subarray(0, 8).equals(MAGIC)) {
    throw new Error('The encrypted file is not in the expected format.');
  }
  const salt = blob.subarray(8, 24);
  const iv = blob.subarray(24, 36);
  const tag = blob.subarray(36, 52);
  const ciphertext = blob.subarray(52);
  const passphrase = await promptHidden('Passphrase (announced at the session): ');
  const decipher = crypto.createDecipheriv('aes-256-gcm', deriveKey(passphrase, salt), iv);
  decipher.setAuthTag(tag);
  let plaintext;
  try {
    plaintext = Buffer.concat([decipher.update(ciphertext), decipher.final()]);
  } catch {
    throw new Error('Decryption failed — wrong passphrase, or the file is corrupted.');
  }
  fs.writeFileSync(PLAIN_FILE, plaintext, { mode: 0o600 });
  console.log(`Wrote ${path.relative(process.cwd(), PLAIN_FILE)}`);
}

async function main() {
  const args = process.argv.slice(2);
  if (args[0] === '--encrypt') {
    if (args.length !== 2) {
      throw new Error('Usage: node scripts/decrypt-credentials.cjs --encrypt <ias-binding.json>');
    }
    await encrypt(args[1]);
  } else if (args.length === 0) {
    await decrypt();
  } else {
    throw new Error('Usage: node scripts/decrypt-credentials.cjs [--encrypt <ias-binding.json>]');
  }
}

main().catch((error) => {
  console.error(`Error: ${error.message}`);
  process.exit(1);
});
