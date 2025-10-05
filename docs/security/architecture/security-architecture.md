# Security Architecture

## Principles
Zero-trust, least privilege, encryption everywhere, auditability, resilience.

## Network
- Private networks and VPN for admin access
- Segmented services and restricted egress

## Application
- RBAC with policy enforcement points
- Input validation and output encoding
- Security headers and CSP

## Data
- Field-level encryption for PHI using envelope encryption
- Key management via KMS/HSM with rotation and escrow

## APIs
- Authenticated with short-lived tokens, refresh rotation, and device registration
- Rate limiting and abuse detection

## Mobile
- Device biometrics, secure storage, app attestation, jailbreak/root detection
