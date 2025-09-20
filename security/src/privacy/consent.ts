export type ConsentRecord = {
  userId: string;
  purpose: string;
  granted: boolean;
  ts: number;
};

export class ConsentStore {
  private store = new Map<string, ConsentRecord>();

  grant(userId: string, purpose: string): void {
    const key = `${userId}:${purpose}`;
    this.store.set(key, { userId, purpose, granted: true, ts: Date.now() });
  }

  revoke(userId: string, purpose: string): void {
    const key = `${userId}:${purpose}`;
    this.store.set(key, { userId, purpose, granted: false, ts: Date.now() });
  }

  hasConsent(userId: string, purpose: string): boolean {
    const key = `${userId}:${purpose}`;
    const rec = this.store.get(key);
    return !!rec && rec.granted;
  }
}
