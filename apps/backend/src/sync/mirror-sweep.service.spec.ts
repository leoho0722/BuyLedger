// 連帶 import firebase-admin (ESM jose)，jest (CJS) 需 mock
jest.mock('firebase-admin/app', () => ({
  initializeApp: jest.fn(),
  getApps: jest.fn(() => []),
  cert: jest.fn(),
}));
jest.mock('firebase-admin/auth', () => ({ getAuth: jest.fn() }));
jest.mock('firebase-admin/firestore', () => ({ getFirestore: jest.fn() }));
jest.mock('firebase-admin/storage', () => ({ getStorage: jest.fn() }));

import { MirrorSweepService } from './mirror-sweep.service';

const FIXED_ISO = '2024-01-01T00:00:00.000Z';

function makeRow(over: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    id: 'ORD1',
    ownerUid: 'U1',
    customerName: '王',
    customerInitials: 'W',
    customerTier: 'new',
    status: 'quoting',
    currency: 'TWD',
    date: new Date(FIXED_ISO),
    items: [],
    itemCost: '0',
    domesticShipping: '0',
    internationalShipping: '0',
    foreignDomesticShipping: '0',
    cardFeeRate: '0',
    platformFeeRate: '0',
    paymentFeeRate: '0',
    chargedAmount: '100',
    cardlessDeductionAmount: '0',
    cardlessSupplementAmount: '0',
    orderSource: '未指定',
    categories: ['未分類'],
    paymentMethod: '',
    notes: '',
    verificationStatus: '',
    campaignNames: [],
    paymentReceiptStatus: 'pending',
    isCashOnDelivery: false,
    photos: [],
    mergedSourceIDs: [],
    fieldClocks: { chargedAmount: '0000000001000:000000:device-a' },
    deletedAt: null,
    deleteClock: '',
    mirrorDirty: true,
    mirrorPendingSinceClock: '0000000001000:000000:server',
    ...over,
  };
}

describe('MirrorSweepService', () => {
  function makeService(rows: Record<string, unknown>[]) {
    const store = new Map<string, Record<string, unknown>>();
    for (const r of rows) store.set(r.id as string, r);

    const prisma = {
      order: {
        findMany: jest.fn(async ({ where }: { where: Record<string, unknown> }) => {
          const out: Record<string, unknown>[] = [];
          for (const r of store.values()) {
            if (where.mirrorDirty !== undefined && r.mirrorDirty !== where.mirrorDirty) continue;
            out.push(r);
          }
          return out;
        }),
        updateMany: jest.fn(async ({ where, data }: { where: { id?: string }; data: Record<string, unknown> }) => {
          if (where.id && store.has(where.id)) {
            store.set(where.id, { ...store.get(where.id), ...data });
            return { count: 1 };
          }
          return { count: 0 };
        }),
        deleteMany: jest.fn(async () => ({ count: 0 })),
      },
    };
    const mirror = {
      mirrorOrder: jest.fn(async () => true),
      mirrorOrderTombstone: jest.fn(async () => true),
    };
    const orders = {
      purgeExpiredTombstones: jest.fn(async () => 0),
    };
    const service = new MirrorSweepService(prisma as never, mirror as never, orders as never);
    return { service, prisma, mirror, orders, store };
  }

  it('re-mirrors a dirty order from Postgres and clears the dirty flag', async () => {
    const { service, mirror, prisma, store } = makeService([makeRow()]);
    await service.sweep();
    expect(mirror.mirrorOrder).toHaveBeenCalledWith(
      'U1',
      expect.objectContaining({ id: 'ORD1' }),
      expect.objectContaining({ writerId: 'server' }),
    );
    expect(prisma.order.updateMany).toHaveBeenCalledWith({
      where: { id: 'ORD1', ownerUid: 'U1' },
      data: { mirrorDirty: false, mirrorPendingSinceClock: null },
    });
    expect(store.get('ORD1')!.mirrorDirty).toBe(false);
  });

  it('re-mirrors a dirty tombstone row as an explicit tombstone', async () => {
    const { service, mirror } = makeService([
      makeRow({ deletedAt: new Date(FIXED_ISO), deleteClock: '0000000002000:000000:server' }),
    ]);
    await service.sweep();
    expect(mirror.mirrorOrderTombstone).toHaveBeenCalledWith(
      'U1',
      expect.objectContaining({ id: 'ORD1' }),
      '0000000002000:000000:server',
      expect.objectContaining({ writerId: 'server' }),
    );
    expect(mirror.mirrorOrder).not.toHaveBeenCalled();
  });

  it('leaves the row dirty when re-mirror still fails', async () => {
    const { service, mirror, prisma, store } = makeService([makeRow()]);
    mirror.mirrorOrder.mockResolvedValueOnce(false);
    await service.sweep();
    expect(prisma.order.updateMany).not.toHaveBeenCalled();
    expect(store.get('ORD1')!.mirrorDirty).toBe(true);
  });

  it('caps the batch at the per-round limit', async () => {
    const rows = Array.from({ length: 150 }, (_, i) => makeRow({ id: `ORD${i}` }));
    const { service, prisma } = makeService(rows);
    await service.sweep();
    expect(prisma.order.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ take: 100 }),
    );
  });

  it('purges expired tombstones as part of the sweep', async () => {
    const { service, orders } = makeService([makeRow()]);
    await service.sweep();
    expect(orders.purgeExpiredTombstones).toHaveBeenCalled();
  });
});
