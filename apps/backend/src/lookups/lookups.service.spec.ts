// 載入 LookupsService 會經由 FirestoreMirrorService 連帶 import firebase-admin (ESM jose)，
// 需 mock
jest.mock('firebase-admin/app', () => ({
  initializeApp: jest.fn(),
  getApps: jest.fn(() => []),
  cert: jest.fn(),
}));
jest.mock('firebase-admin/auth', () => ({ getAuth: jest.fn() }));
jest.mock('firebase-admin/firestore', () => ({ getFirestore: jest.fn() }));
jest.mock('firebase-admin/storage', () => ({ getStorage: jest.fn() }));

import { NowService } from '../common/now.service';
import { HlcService } from '../sync/hlc.service';
import { LookupsService } from './lookups.service';

// lookups 採複合主鍵 [ownerUid, name]，列舉與寫入一律帶 ownerUid 圈選使用者
describe('LookupsService uid scoping', () => {
  function makeService(overrides: Record<string, unknown> = {}) {
    const prisma = {
      category: {
        findMany: jest.fn().mockResolvedValue([]),
        upsert: jest.fn().mockResolvedValue({}),
        deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
      },
      orderSource: {
        findMany: jest.fn().mockResolvedValue([]),
        deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
      },
      paymentMethod: {
        findMany: jest.fn().mockResolvedValue([]),
      },
      ...overrides,
    };
    const orders = {
      cascadeStripCategory: jest.fn().mockResolvedValue(undefined),
      cascadeStripScalar: jest.fn().mockResolvedValue(undefined),
    };
    const mirror = {
      upsert: jest.fn().mockResolvedValue(true),
      remove: jest.fn().mockResolvedValue(true),
      mirrorTombstone: jest.fn().mockResolvedValue(true),
    };
    const hlc = new HlcService(new NowService());
    const service = new LookupsService(prisma as never, orders as never, mirror as never, hlc);
    return { service, prisma, orders, mirror };
  }

  it('listCategories scopes findMany by the caller ownerUid', async () => {
    const { service, prisma } = makeService();
    await service.listCategories('user-A');
    expect(prisma.category.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { ownerUid: 'user-A' } }),
    );
  });

  it('addCategory upserts with the composite [ownerUid, name] key and a recordClock', async () => {
    const { service, prisma } = makeService();
    await service.addCategory('user-A', '美妝');
    const call = (prisma.category.upsert as jest.Mock).mock.calls[0][0];
    expect(call.where).toEqual({ ownerUid_name: { ownerUid: 'user-A', name: '美妝' } });
    expect(call.create.ownerUid).toBe('user-A');
    expect(call.create.name).toBe('美妝');
    expect(typeof call.create.recordClock).toBe('string');
    expect(call.create.recordClock.length).toBeGreaterThan(0);
  });

  // 刪除採 tombstone (非硬刪) 並 cascade-strip 訂單參照
  it('removeCategory cascade-strips order references and mirrors a tombstone, not a hard delete', async () => {
    const { service, prisma, orders, mirror } = makeService();
    await service.removeCategory('user-A', '美妝');
    expect(orders.cascadeStripCategory).toHaveBeenCalledWith('user-A', '美妝');
    expect(prisma.category.deleteMany).toHaveBeenCalledWith({
      where: { ownerUid: 'user-A', name: '美妝' },
    });
    expect(mirror.mirrorTombstone).toHaveBeenCalledWith(
      'user-A',
      'categories',
      '美妝',
      expect.objectContaining({ recordClock: expect.any(String) }),
    );
    expect(mirror.remove).not.toHaveBeenCalled();
  });

  it('removeOrderSource cascade-strips the scalar reference and mirrors a tombstone', async () => {
    const { service, orders, mirror } = makeService();
    await service.removeOrderSource('user-A', '蝦皮');
    expect(orders.cascadeStripScalar).toHaveBeenCalledWith('user-A', 'orderSource', '蝦皮');
    expect(mirror.mirrorTombstone).toHaveBeenCalledWith(
      'user-A',
      'orderSources',
      '蝦皮',
      expect.objectContaining({ recordClock: expect.any(String) }),
    );
  });
});
