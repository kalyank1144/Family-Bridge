import { createHmac, createHash } from 'crypto';
import { createReadStream } from 'fs';
import readline from 'readline';

export async function verifyAuditChain(filePath: string, hmacSecret: string): Promise<{ ok: boolean; count: number; errorLine?: number }>{
  let prev = 'GENESIS';
  let count = 0;
  const rl = readline.createInterface({ input: createReadStream(filePath), crlfDelay: Infinity });
  for await (const line of rl) {
    if (!line.trim()) continue;
    const obj = JSON.parse(line);
    const shadow = { id: obj.id, ts: obj.ts, actor: obj.actor, action: obj.action, resource: obj.resource, subject: obj.subject, outcome: obj.outcome, phi: obj.phi, reason: obj.reason, ip: obj.ip, userAgent: obj.userAgent, metadata: obj.metadata };
    const body = JSON.stringify(shadow);
    const bodyHash = createHash('sha256').update(body).digest('hex');
    const hash = createHash('sha256').update(prev + bodyHash).digest('hex');
    const hmac = createHmac('sha256', hmacSecret).update(hash).digest('hex');
    if (obj.prevHash !== prev || obj.hash !== hash || obj.hmac !== hmac) return { ok: false, count, errorLine: count + 1 };
    prev = hash;
    count++;
  }
  return { ok: true, count };
}
