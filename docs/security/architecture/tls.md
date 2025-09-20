# TLS 1.3 Configuration

## Requirements
- TLS 1.3 only for external endpoints
- Strong ciphers and PFS
- HSTS with preload for web origins
- OCSP stapling and certificate pinning where supported

## Server Notes
- Rotate certificates at least every 90 days
- Disable TLS compression and renegotiation
