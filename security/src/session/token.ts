import jwt from 'jsonwebtoken';
import { randomUUID } from 'crypto';

export type TokenSecrets = { accessSecret: string; refreshSecret: string };

export function createAccessToken(
  payload: { sub: string; role: string; deviceId?: string },
  secret: string,
  expiresIn = '15m'
): string {
  return jwt.sign(payload, secret, { algorithm: 'HS256', expiresIn, jwtid: randomUUID() });
}

export function createRefreshToken(
  payload: { sub: string; familyId?: string },
  secret: string,
  expiresIn = '30d'
): { token: string; jti: string; familyId: string } {
  const familyId = payload.familyId ?? randomUUID();
  const jti = randomUUID();
  const token = jwt.sign({ sub: payload.sub, familyId }, secret, {
    algorithm: 'HS256',
    expiresIn,
    jwtid: jti,
  });
  return { token, jti, familyId };
}

export function rotateRefreshToken(
  oldToken: string,
  secret: string,
  expiresIn = '30d'
): { token: string; jti: string; familyId: string; revokedJti: string } {
  const decoded = jwt.verify(oldToken, secret) as jwt.JwtPayload;
  const familyId = String(decoded.familyId);
  const revokedJti = String(decoded.jti);
  const next = createRefreshToken({ sub: String(decoded.sub), familyId }, secret, expiresIn);
  return { ...next, revokedJti };
}

export function verifyToken<T = jwt.JwtPayload>(token: string, secret: string): T {
  return jwt.verify(token, secret) as T;
}
