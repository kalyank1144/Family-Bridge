# Security Policy

## Supported
Security features are maintained on the main branch. Report vulnerabilities privately.

## Reporting a Vulnerability
- Email: security@familybridge.example (placeholder)
- Do not create public issues for vulnerabilities.
- Provide steps to reproduce, impact, and proposed severity.

## Disclosure
We follow responsible disclosure. We will acknowledge receipt within 2 business days, provide status updates at least weekly, and coordinate a remediation timeline and release notes.

## Hardening
- TLS 1.3 required; strong ciphers only
- Keys are rotated at least every 90 days
- MFA required for all administrative access
- Principle of least privilege enforced via RBAC
- Secrets are never committed; gitleaks and GitHub secret scanning are enabled
