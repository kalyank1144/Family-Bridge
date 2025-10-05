# Audit Logging

## Scope
Log all access to PHI and security-sensitive actions.

## Minimum Fields
- id, timestamp, actor, action, resource, subject, outcome
- phi flag, reason/purpose, request ip, user agent

## Integrity
Events are chained with a rolling hash and HMAC. See `security/src/audit/logger.ts` and verify via `npm run security:verify-logs`.

## Retention
Retain audit logs for at least 6 years.

## Review
- Daily automated anomaly detection
- Weekly manual review
- Monthly compliance report
