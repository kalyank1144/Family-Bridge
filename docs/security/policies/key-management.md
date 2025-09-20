# Key Management Policy

## Generation
Keys generated in FIPS-validated modules. Unique DEKs per data domain; KEKs in KMS/HSM.

## Rotation
- DEKs: every 90 days or upon compromise
- KEKs: annually or upon compromise

## Storage
Keys are never stored in code or config. Use KMS and environment-specific access controls.

## Escrow and Recovery
Documented escrow procedures and break-glass with approvals and audit logging.
