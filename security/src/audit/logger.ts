import { createHmac, createHash } from 'crypto';
import { randomUUID } from 'crypto';
import { mkdirSync, existsSync } from 'fs';
import { appendFile } from 'fs/promises';
import { dirname } from 'path';

export type AuditEvent = {
  id?: string;
  ts?: number;
  actor: string;
  action: string;
  resource?: string;
  subject?: string;
  outcome?: 'success' | 'failure';
  phi?: boolean;
  reason?: string;
  ip?: string;
  userAgent?: string;
  metadata?: Record<string, unknown>;
};

export class AuditLogger {
  private prevHash = 'GENESIS';

  constructor(private filePath: string, private hmacSecret: string) {}

  async log(ev: AuditEvent): Promise<void> {
    const dir = dirname(this.filePath);
    if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
    const base = {
      id: ev.id ?? randomUUID(),
      ts: ev.ts ?? Date.now(),
      actor: ev.actor,
      action: ev.action,
      resource: ev.resource,
      subject: ev.subject,
      outcome: ev.outcome ?? 'success',
      phi: ev.phi ?? false,
      reason: ev.reason,
      ip: ev.ip,
      userAgent: ev.userAgent,
      metadata: ev.metadata ?? {},
    };
    const body = JSON.stringify(base);
    const bodyHash = createHash('sha256').update(body).digest('hex');
    const hash = createHash('sha256').update(this.prevHash + bodyHash).digest('hex');
    const hmac = createHmac('sha256', this.hmacSecret).update(hash).digest('hex');
    const line = JSON.stringify({ ...base, prevHash: this.prevHash, hash, hmac });
    await appendFile(this.filePath, line + '\n', { encoding: 'utf8' });
    this.prevHash = hash;
  }
}
