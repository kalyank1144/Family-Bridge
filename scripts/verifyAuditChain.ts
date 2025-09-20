import { verifyAuditChain } from '../security/src/audit/verify.js';

const file = process.argv[2] ?? 'logs/audit.jsonl';
const secret = process.env.AUDIT_HMAC_SECRET ?? 'dev-secret';
verifyAuditChain(file, secret).then((res) => {
  if (res.ok) {
    console.log(`OK ${res.count}`);
    process.exit(0);
  } else {
    console.error(`FAIL line=${res.errorLine}`);
    process.exit(1);
  }
});
