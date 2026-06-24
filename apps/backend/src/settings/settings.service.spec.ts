// 載入 SettingsService 會經由 FirestoreMirrorService 連帶 import firebase-admin (ESM jose)，需 mock
jest.mock('firebase-admin/app', () => ({
  initializeApp: jest.fn(),
  getApps: jest.fn(() => []),
  cert: jest.fn(),
}));
jest.mock('firebase-admin/auth', () => ({ getAuth: jest.fn() }));
jest.mock('firebase-admin/firestore', () => ({ getFirestore: jest.fn() }));
jest.mock('firebase-admin/storage', () => ({ getStorage: jest.fn() }));

import { SettingsService } from './settings.service';

// 對齊 spec「Settings are per-user」：以 uid 為鍵讀寫各自的設定
describe('SettingsService per-user', () => {
  function makeService() {
    const upsert = jest.fn().mockResolvedValue({
      appearance: 'system',
      notifications: true,
      useAiSummary: false,
      aiSummaryModel: 'm',
      defaultCurrency: 'TWD',
      monthlyProfitGoal: '80000',
    });
    const prisma = { settings: { upsert } };
    const mirror = { upsert: jest.fn().mockResolvedValue(undefined) };
    const service = new SettingsService(prisma as never, mirror as never);
    return { service, upsert };
  }

  it('get upserts keyed by the caller ownerUid', async () => {
    const { service, upsert } = makeService();
    await service.get('user-Z');
    expect(upsert).toHaveBeenCalledWith(
      expect.objectContaining({ where: { ownerUid: 'user-Z' }, create: { ownerUid: 'user-Z' } }),
    );
  });

  it('update upserts keyed by the caller ownerUid', async () => {
    const { service, upsert } = makeService();
    await service.update('user-Z', { appearance: 'dark' });
    expect(upsert).toHaveBeenCalledWith(
      expect.objectContaining({ where: { ownerUid: 'user-Z' } }),
    );
  });
});
