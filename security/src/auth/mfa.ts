import { authenticator } from 'otplib';
import { randomBytes } from 'crypto';

export function generateSecret(): string {
  return authenticator.generateSecret();
}

export function generateKeyUri(label: string, issuer: string, secret: string): string {
  return authenticator.keyuri(label, issuer, secret);
}

export function verifyToken(secret: string, token: string): boolean {
  return authenticator.verify({ token, secret });
}

export function generateBackupCodes(count = 10): string[] {
  return Array.from({ length: count }).map(() => randomBytes(5).toString('hex'));
}
