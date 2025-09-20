# SIEM Integration

## Format
Emit JSON Lines with stable schema and send to SIEM via secure syslog or HTTPS.

## Transport
- TLS mutual auth where supported
- Least-privileged credentials

## Fields
Include normalized fields for actor, action, resource, subject, geo, device, severity, phi flag, and chain hash.
