import { randomBytes } from 'crypto';

export interface KeyStore {
  getActiveKey(): Promise<{ keyId: string; key: Buffer }>;
  getKey(keyId: string): Promise<Buffer>;
  rotate(): Promise<{ keyId: string; key: Buffer }>;
  list(): Promise<string[]>;
}

export class InMemoryKeyStore implements KeyStore {
  private keys = new Map<string, Buffer>();
  private activeKeyId: string;

  constructor(initialKeyId?: string, initialKey?: Buffer) {
    if (initialKeyId && initialKey) {
      this.keys.set(initialKeyId, initialKey);
      this.activeKeyId = initialKeyId;
    } else {
      const keyId = this.generateKeyId();
      const key = randomBytes(32);
      this.keys.set(keyId, key);
      this.activeKeyId = keyId;
    }
  }

  async getActiveKey(): Promise<{ keyId: string; key: Buffer }> {
    const key = this.keys.get(this.activeKeyId);
    if (!key) throw new Error('Active key not found');
    return { keyId: this.activeKeyId, key };
    }

  async getKey(keyId: string): Promise<Buffer> {
    const key = this.keys.get(keyId);
    if (!key) throw new Error('Key not found');
    return key;
  }

  async rotate(): Promise<{ keyId: string; key: Buffer }> {
    const keyId = this.generateKeyId();
    const key = randomBytes(32);
    this.keys.set(keyId, key);
    this.activeKeyId = keyId;
    return { keyId, key };
  }

  async list(): Promise<string[]> {
    return Array.from(this.keys.keys());
  }

  private generateKeyId(): string {
    return randomBytes(16).toString('hex');
  }
}
