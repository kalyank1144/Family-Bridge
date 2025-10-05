import { createCipheriv, createDecipheriv, randomBytes } from 'crypto';
import { InMemoryKeyStore, KeyStore } from './keystore.js';

export type EncryptedPayload = {
  alg: 'AES-256-GCM';
  keyId: string;
  iv: string;
  tag: string;
  ciphertext: string;
  aad?: string;
};

function b64url(buf: Buffer): string {
  return buf
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/g, '');
}

function fromb64url(s: string): Buffer {
  const b = s.replace(/-/g, '+').replace(/_/g, '/');
  return Buffer.from(b + '='.repeat((4 - (b.length % 4)) % 4), 'base64');
}

export class EnvelopeEncryptor {
  private keystore: KeyStore;

  constructor(keystore?: KeyStore) {
    this.keystore = keystore ?? new InMemoryKeyStore();
  }

  async encrypt(plaintext: Buffer | string, aad?: Buffer): Promise<EncryptedPayload> {
    const { keyId, key } = await this.keystore.getActiveKey();
    const iv = randomBytes(12);
    const cipher = createCipheriv('aes-256-gcm', key, iv);
    if (aad) cipher.setAAD(aad);
    const pt = Buffer.isBuffer(plaintext) ? plaintext : Buffer.from(plaintext);
    const ciphertext = Buffer.concat([cipher.update(pt), cipher.final()]);
    const tag = cipher.getAuthTag();
    return {
      alg: 'AES-256-GCM',
      keyId,
      iv: b64url(iv),
      tag: b64url(tag),
      ciphertext: b64url(ciphertext),
      aad: aad ? b64url(aad) : undefined,
    };
  }

  async decrypt(payload: EncryptedPayload, aad?: Buffer): Promise<Buffer> {
    const key = await this.keystore.getKey(payload.keyId);
    const iv = fromb64url(payload.iv);
    const decipher = createDecipheriv('aes-256-gcm', key, iv);
    const tag = fromb64url(payload.tag);
    decipher.setAuthTag(tag);
    if (aad) decipher.setAAD(aad);
    const ct = fromb64url(payload.ciphertext);
    const plaintext = Buffer.concat([decipher.update(ct), decipher.final()]);
    return plaintext;
  }
}
