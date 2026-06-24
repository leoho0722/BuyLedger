// OrdersService 會間接 import firebase-admin (ESM jose)，jest 須 mock
jest.mock('firebase-admin/app', () => ({
  initializeApp: jest.fn(),
  getApps: jest.fn(() => []),
  cert: jest.fn(),
}));
jest.mock('firebase-admin/auth', () => ({ getAuth: jest.fn() }));
jest.mock('firebase-admin/firestore', () => ({ getFirestore: jest.fn() }));
jest.mock('firebase-admin/storage', () => ({ getStorage: jest.fn() }));

import { BadRequestException } from '@nestjs/common';

import { NowService } from '../common/now.service';
import { HlcService } from '../sync/hlc.service';
import { OrdersService } from './orders.service';

const FIXED_ISO = '2024-01-01T00:00:00.000Z';
const NOW_MS = new Date(FIXED_ISO).getTime();

const enc = (p: number, c: number, w: string): string =>
  `${String(p).padStart(13, '0')}:${String(c).padStart(6, '0')}:${w}`;

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
    fieldClocks: {},
    deletedAt: null,
    deleteClock: '',
    ...over,
  };
}

function makeService(initial?: Record<string, unknown>) {
  const store = new Map<string, Record<string, unknown>>();
  if (initial) store.set(initial.id as string, initial);

  const prisma = {
    order: {
      findFirst: jest.fn(async ({ where }: { where: { id: string; ownerUid: string } }) => {
        const row = store.get(where.id);
        return row && row.ownerUid === where.ownerUid ? row : null;
      }),
      findUnique: jest.fn(async ({ where }: { where: { id: string } }) => store.get(where.id) ?? null),
      upsert: jest.fn(
        async ({ where, create, update }: { where: { id: string }; create: Record<string, unknown>; update: Record<string, unknown> }) => {
          const existing = store.get(where.id);
          const next = existing ? { ...existing, ...update } : { ...create };
          store.set(where.id, next);
          return next;
        },
      ),
      update: jest.fn(
        async ({ where, data }: { where: { id: string }; data: Record<string, unknown> }) => {
          const existing = store.get(where.id) ?? {};
          const next = { ...existing, ...data };
          store.set(where.id, next);
          return next;
        },
      ),
      updateMany: jest.fn(
        async ({ where, data }: { where: { id?: string }; data: Record<string, unknown> }) => {
          if (where.id && store.has(where.id)) {
            store.set(where.id, { ...store.get(where.id), ...data });
            return { count: 1 };
          }
          return { count: 0 };
        },
      ),
      deleteMany: jest.fn(async () => ({ count: 0 })),
    },
    paymentMethod: {
      findUnique: jest.fn(async () => null),
      findMany: jest.fn(async () => []),
    },
  };

  process.env.BUYLEDGER_FIXED_NOW = FIXED_ISO;
  const now = new NowService();
  const hlc = new HlcService(now);
  const ids = { uuid: () => 'uuid-x', newOrderId: () => 'BL-NEW' };
  const mirror = {
    mirrorOrder: jest.fn(async () => true),
    mirrorOrderTombstone: jest.fn(async () => true),
    mirrorTombstone: jest.fn(async () => true),
    upsert: jest.fn(async () => true),
    remove: jest.fn(async () => true),
  };
  const service = new OrdersService(
    prisma as never,
    now as never,
    ids as never,
    mirror as never,
    hlc as never,
  );
  return { service, prisma, mirror, store };
}

afterEach(() => {
  delete process.env.BUYLEDGER_FIXED_NOW;
});

describe('OrdersService.patch field-level merge', () => {
  it('creates a new order from a sparse patch (upsert by client id)', async () => {
    const { service, mirror, store } = makeService();
    const clock = enc(NOW_MS, 0, 'device-a');
    const res = await service.patch('U1', 'ORD1', {
      changedFields: { customerName: 'A', chargedAmount: '250' },
      fieldClocks: { customerName: clock, chargedAmount: clock },
    });
    expect(res.order.customer.name).toBe('A');
    expect(res.order.chargedAmount).toBe('250');
    expect(res.appliedFieldClocks).toEqual({ customerName: clock, chargedAmount: clock });
    expect(store.has('ORD1')).toBe(true);
    expect(mirror.mirrorOrder).toHaveBeenCalledWith(
      'U1',
      expect.objectContaining({ id: 'ORD1' }),
      expect.objectContaining({
        fieldClocks: expect.objectContaining({ chargedAmount: clock }),
        writerId: 'server',
      }),
    );
  });

  it('auto-merges disjoint fields: a chargedAmount patch keeps the other device customerName', async () => {
    const cA = enc(NOW_MS, 0, 'device-a');
    const { service } = makeService(
      makeRow({
        customerName: '王',
        chargedAmount: '100',
        fieldClocks: { customerName: cA, chargedAmount: cA },
      }),
    );
    const cB = enc(NOW_MS, 5, 'device-b');
    const res = await service.patch('U1', 'ORD1', {
      changedFields: { chargedAmount: '200' },
      fieldClocks: { chargedAmount: cB },
    });
    expect(res.order.customer.name).toBe('王');
    expect(res.order.chargedAmount).toBe('200');
    expect(res.appliedFieldClocks).toEqual({ chargedAmount: cB });
  });

  it('a same-field lower-clock patch loses; applied clock is the stored authority', async () => {
    const high = enc(NOW_MS, 5, 'device-a');
    const { service } = makeService(
      makeRow({ chargedAmount: '100', fieldClocks: { chargedAmount: high } }),
    );
    const low = enc(NOW_MS, 0, 'device-b');
    const res = await service.patch('U1', 'ORD1', {
      changedFields: { chargedAmount: '999' },
      fieldClocks: { chargedAmount: low },
    });
    expect(res.order.chargedAmount).toBe('100');
    expect(res.appliedFieldClocks).toEqual({ chargedAmount: high });
  });

  it('rejects a changed field with no clock', async () => {
    const { service } = makeService();
    await expect(
      service.patch('U1', 'ORD1', {
        changedFields: { chargedAmount: '5' },
        fieldClocks: {},
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });
});
