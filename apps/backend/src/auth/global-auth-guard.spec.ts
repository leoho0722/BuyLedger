// 載入 guard 會經由 FirebaseService 連帶 import firebase-admin (ESM jose)，測試一律 mock。
jest.mock('firebase-admin/app', () => ({
  initializeApp: jest.fn(),
  getApps: jest.fn(() => []),
  cert: jest.fn(),
}));
jest.mock('firebase-admin/auth', () => ({ getAuth: jest.fn() }));
jest.mock('firebase-admin/firestore', () => ({ getFirestore: jest.fn() }));
jest.mock('firebase-admin/storage', () => ({ getStorage: jest.fn() }));

import { Controller, Get, INestApplication } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { FirebaseAuthGuard } from './firebase-auth.guard';
import { CurrentUid } from './current-user.decorator';
import { Public } from './public.decorator';
import { FirebaseService } from '../firebase/firebase.service';

@Controller()
class ProbeController {
  @Get('protected')
  protectedRoute(@CurrentUid() uid: string): { uid: string } {
    return { uid };
  }

  @Public()
  @Get('open')
  openRoute(): { ok: boolean } {
    return { ok: true };
  }
}

// 對齊 spec「Backend verifies Firebase ID tokens on protected endpoints」的全域套用面：
// guard 經 APP_GUARD 全域註冊後，預設端點需 token、@Public 端點放行。
describe('global FirebaseAuthGuard (integration)', () => {
  let app: INestApplication;
  const verifyIdToken = jest.fn();

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      controllers: [ProbeController],
      providers: [
        { provide: FirebaseService, useValue: { auth: { verifyIdToken } } },
        { provide: APP_GUARD, useClass: FirebaseAuthGuard },
      ],
    }).compile();
    app = moduleRef.createNestApplication();
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  afterEach(() => jest.clearAllMocks());

  it('protected route returns 401 without a token', async () => {
    await request(app.getHttpServer()).get('/protected').expect(401);
  });

  it('protected route returns 200 with a valid token and echoes the uid', async () => {
    verifyIdToken.mockResolvedValueOnce({ uid: 'user-77' });
    await request(app.getHttpServer())
      .get('/protected')
      .set('Authorization', 'Bearer good-token')
      .expect(200, { uid: 'user-77' });
  });

  it('public route returns 200 without a token', async () => {
    await request(app.getHttpServer()).get('/open').expect(200, { ok: true });
  });
});
