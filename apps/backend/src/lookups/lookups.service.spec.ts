// 載入 LookupsService 會經由 FirestoreMirrorService 連帶 import firebase-admin (ESM jose)，需 mock。
jest.mock('firebase-admin/app', () => ({
  initializeApp: jest.fn(),
  getApps: jest.fn(() => []),
  cert: jest.fn(),
}));
jest.mock('firebase-admin/auth', () => ({ getAuth: jest.fn() }));
jest.mock('firebase-admin/firestore', () => ({ getFirestore: jest.fn() }));
jest.mock('firebase-admin/storage', () => ({ getStorage: jest.fn() }));

import { LookupsService } from './lookups.service';

// 對齊 spec「Reads are scoped to the caller's uid」：lookups 採複合主鍵 [ownerUid, name]，
// 列舉與寫入一律帶 ownerUid，不同使用者各自一份。
describe('LookupsService uid scoping', () => {
  function makeService() {
    const prisma = {
      category: {
        findMany: jest.fn().mockResolvedValue([]),
        upsert: jest.fn().mockResolvedValue({}),
      },
      paymentMethod: {
        findMany: jest.fn().mockResolvedValue([]),
      },
    };
    const orders = {};
    const mirror = {
      upsert: jest.fn().mockResolvedValue(undefined),
      remove: jest.fn().mockResolvedValue(undefined),
    };
    const service = new LookupsService(prisma as never, orders as never, mirror as never);
    return { service, prisma };
  }

  it('listCategories scopes findMany by the caller ownerUid', async () => {
    const { service, prisma } = makeService();
    await service.listCategories('user-A');
    expect(prisma.category.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { ownerUid: 'user-A' } }),
    );
  });

  it('addCategory upserts with the composite [ownerUid, name] key', async () => {
    const { service, prisma } = makeService();
    await service.addCategory('user-A', '美妝');
    expect(prisma.category.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { ownerUid_name: { ownerUid: 'user-A', name: '美妝' } },
        create: { ownerUid: 'user-A', name: '美妝' },
      }),
    );
  });
});
