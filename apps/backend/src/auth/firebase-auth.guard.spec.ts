// 載入 guard 會經由 FirebaseService 連帶 import firebase-admin (ESM jose)，單元測試一律 mock。
jest.mock('firebase-admin/app', () => ({
  initializeApp: jest.fn(),
  getApps: jest.fn(() => []),
  cert: jest.fn(),
}));
jest.mock('firebase-admin/auth', () => ({ getAuth: jest.fn() }));
jest.mock('firebase-admin/firestore', () => ({ getFirestore: jest.fn() }));
jest.mock('firebase-admin/storage', () => ({ getStorage: jest.fn() }));

import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { FirebaseAuthGuard } from './firebase-auth.guard';
import { FirebaseService } from '../firebase/firebase.service';

// 對齊 spec「Backend verifies Firebase ID tokens on protected endpoints」與
// 「Authenticated request context exposes the caller uid」。
describe('FirebaseAuthGuard', () => {
  const verifyIdToken = jest.fn();
  const firebase = { auth: { verifyIdToken } } as unknown as FirebaseService;
  const isPublic = jest.fn(() => false);
  const reflector = { getAllAndOverride: isPublic } as unknown as Reflector;
  const guard = new FirebaseAuthGuard(firebase, reflector);

  function contextFor(headers: Record<string, string>): {
    ctx: ExecutionContext;
    request: { headers: Record<string, string>; uid?: string };
  } {
    const request: { headers: Record<string, string>; uid?: string } = { headers };
    const ctx = {
      switchToHttp: () => ({ getRequest: () => request }),
      getHandler: () => undefined,
      getClass: () => undefined,
    } as unknown as ExecutionContext;
    return { ctx, request };
  }

  afterEach(() => {
    jest.clearAllMocks();
    isPublic.mockReturnValue(false);
  });

  it('rejects a request without an Authorization header (401)', async () => {
    const { ctx } = contextFor({});
    await expect(guard.canActivate(ctx)).rejects.toBeInstanceOf(UnauthorizedException);
    expect(verifyIdToken).not.toHaveBeenCalled();
  });

  it('rejects a non-Bearer Authorization header (401)', async () => {
    const { ctx } = contextFor({ authorization: 'Basic abc123' });
    await expect(guard.canActivate(ctx)).rejects.toBeInstanceOf(UnauthorizedException);
    expect(verifyIdToken).not.toHaveBeenCalled();
  });

  it('rejects an invalid token (401)', async () => {
    verifyIdToken.mockRejectedValueOnce(new Error('token expired'));
    const { ctx } = contextFor({ authorization: 'Bearer bad-token' });
    await expect(guard.canActivate(ctx)).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('passes a valid token and exposes the caller uid on the request', async () => {
    verifyIdToken.mockResolvedValueOnce({ uid: 'user-123' });
    const { ctx, request } = contextFor({ authorization: 'Bearer good-token' });
    await expect(guard.canActivate(ctx)).resolves.toBe(true);
    expect(verifyIdToken).toHaveBeenCalledWith('good-token');
    expect(request.uid).toBe('user-123');
  });

  it('skips verification for @Public() endpoints', async () => {
    isPublic.mockReturnValue(true);
    const { ctx } = contextFor({});
    await expect(guard.canActivate(ctx)).resolves.toBe(true);
    expect(verifyIdToken).not.toHaveBeenCalled();
  });
});
