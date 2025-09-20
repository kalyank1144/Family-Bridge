# HIPAA Risk Assessment

## Methodology
- Identify assets, data flows, and PHI repositories
- Identify threats and vulnerabilities
- Assess likelihood and impact
- Determine existing controls and residual risk
- Prioritize mitigations and track in `RISK_REGISTER.md`
- Review at least annually and after major changes

## Assets
- Application services, APIs, databases, mobile apps, admin consoles
- Secrets and keys, CI pipelines, third-party integrations

## Threats
- Unauthorized access, credential stuffing, insider threats
- Data exfiltration, malware/ransomware, supply chain attacks
- Misconfigurations and insecure defaults

## Controls
- RBAC, MFA, least privilege
- Field-level encryption and key rotation
- Audit logging and SIEM monitoring
- Secure SDLC and CI security

## Residual Risk
Document accepted and mitigated risks with owners and timelines.
