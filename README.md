# Family Bridge Security & HIPAA Compliance Framework

This repository implements an end-to-end security and HIPAA compliance framework for Family Bridge. It provides technical controls, documentation, and CI security automation to protect Protected Health Information (PHI) while preserving usability and performance.

## Scope
- HIPAA compliance documentation and processes
- Encryption for data in transit and at rest, with key rotation
- Role-based access control with granular permissions
- Multi-factor authentication (MFA) support
- Session security with secure token handling and rotation
- Comprehensive audit logging with integrity verification
- Privacy controls and consent management
- Security operations: incident response, breach notification, monitoring
- CI security: CodeQL, dependency review, secret scanning (gitleaks), container scanning

## Repository Structure
- `docs/security/` — HIPAA, policies, incident response, monitoring, architecture
- `security/` — TypeScript security modules (encryption, RBAC, audit, MFA, session, privacy)
- `.github/workflows/` — Security and compliance automation
- `SECURITY.md` — Vulnerability disclosure policy
- `PRIVACY_POLICY.md` — Privacy policy focused on PHI
- `COMPLIANCE_CHECKLIST.md` — HIPAA controls checklist
- `RISK_REGISTER.md` — Risk tracking template

## Quick Start (Libraries)
Install dependencies, then typecheck.

```
npm install
npm run typecheck
```

Import security modules where needed:

```ts
import { EnvelopeEncryptor, InMemoryKeyStore } from './security/src/crypto/encryption';
import { RBAC, DefaultRoles, DefaultPermissions } from './security/src/auth/rbac';
import { AuditLogger } from './security/src/audit/logger';
```

## Compliance
- HIPAA: see `docs/security/HIPAA/` and `COMPLIANCE_CHECKLIST.md`
- BAA template: `docs/security/HIPAA/baa/BAA_TEMPLATE.md`
- Risk assessment: `docs/security/HIPAA/risk-assessment.md`
- PHI classification: `docs/security/HIPAA/phi-classification.md`

## Monitoring
- Audit trail: `docs/security/monitoring/audit-logging.md`
- Compliance reporting: `docs/security/monitoring/compliance-reporting.md`
- SIEM integration: `docs/security/monitoring/siem-integration.md`

## Operations
- Incident response: `docs/security/incident-response/plan.md`
- Breach notification: `docs/security/incident-response/breach-notification.md`
- Emergency access (break-glass): `docs/security/operations/emergency-access.md`
- Device security: `docs/security/operations/device-security.md`

## CI Security
- CodeQL: static analysis for JS/TS
- Dependency Review: supply chain alerts
- Gitleaks: secret scanning
- Trivy: container scanning (if images are added)

## Notes
- TLS 1.3 is required for all external traffic; see `docs/security/architecture/tls.md`.
- Field-level encryption is provided for PHI, with envelope encryption and rotation.
- All audit events are integrity-chained and verifiable via `npm run security:verify-logs`.
