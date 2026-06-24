// 載入 OrdersService 會經由 FirestoreMirrorService 連帶 import firebase-admin (ESM jose)，
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
import { OrdersService } from './orders.service';

const FIXED_ISO = '2024-01-01T00:00:00.000Z';

// 編碼 HLC 字串 p(13):c(6):w (對齊 hlc.ts 編碼)
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
    date: new Date('2024-01-01T00:00:00.000Z'),
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
    orderSource: '蝦皮',
    categories: ['Food', 'Gifts'],
    paymentMethod: '信用卡',
    notes: '',
    verificationStatus: '',
    campaignNames: [],
    paymentReceiptStatus: 'pending',
    isCashOnDelivery: false,
    photos: [],
    mergedSourceIDs: [],
    fieldClocks: {},
    deletedAt: null,
    ...over,
  };
}

function makeService(rows: Record<string, unknown>[]) {
  const store = new Map<string, Record<string, unknown>>();
  for (const r of rows) store.set(r.id as string, r);

  const prisma = {
    order: {
      findMany: jest.fn(async ({ where }: { where: Record<string, unknown> }) => {
        const out: Record<string, unknown>[] = [];
        for (const r of store.values()) {
          if (where.ownerUid && r.ownerUid !== where.ownerUid) continue;
          if (where.deletedAt === null && r.deletedAt) continue;
          const idIn = (where.id as { in?: string[] } | undefined)?.in;
          if (idIn && !idIn.includes(r.id as string)) continue;
          const arrHas = where.categories ?? where.campaignNames;
          if (arrHas && (arrHas as { has?: string }).has !== undefined) {
            const field = where.categories ? 'categories' : 'campaignNames';
            if (!(r[field] as string[]).includes((arrHas as { has: string }).has)) continue;
          }
          if (typeof where.orderSource === 'string' && r.orderSource !== where.orderSource) continue;
          if (typeof where.paymentMethod === 'string' && r.paymentMethod !== where.paymentMethod) continue;
          if (typeof where.verificationStatus === 'string' && r.verificationStatus !== where.verificationStatus)
            continue;
          out.push(r);
        }
        return out;
      }),
      findFirst: jest.fn(async ({ where }: { where: Record<string, unknown> }) => {
        const row = store.get(where.id as string);
        if (!row || row.ownerUid !== where.ownerUid) return null;
        if (where.deletedAt === null && row.deletedAt) return null;
        return row;
      }),
      findUnique: jest.fn(async ({ where }: { where: { id: string } }) => store.get(where.id) ?? null),
      upsert: jest.fn(
        async ({
          where,
          create,
          update,
        }: {
          where: { id: string };
          create: Record<string, unknown>;
          update: Record<string, unknown>;
        }) => {
          const existing = store.get(where.id);
          const next = existing ? { ...existing, ...update } : { ...create };
          store.set(where.id, next);
          return next;
        },
      ),
      update: jest.fn(async ({ where, data }: { where: { id: string }; data: Record<string, unknown> }) => {
        const existing = store.get(where.id) ?? {};
        const next = { ...existing, ...data };
        store.set(where.id, next);
        return next;
      }),
      updateMany: jest.fn(async ({ where, data }: { where: Record<string, unknown>; data: Record<string, unknown> }) => {
        let count = 0;
        for (const [id, r] of [...store.entries()]) {
          if (where.ownerUid && r.ownerUid !== where.ownerUid) continue;
          if (typeof where.orderSource === 'string' && r.orderSource !== where.orderSource) continue;
          if (typeof where.paymentMethod === 'string' && r.paymentMethod !== where.paymentMethod) continue;
          if (typeof where.verificationStatus === 'string' && r.verificationStatus !== where.verificationStatus)
            continue;
          store.set(id, { ...r, ...data });
          count++;
        }
        return { count };
      }),
    },
    paymentMethod: {
      findUnique: jest.fn(async () => null),
      findMany: jest.fn(async () => []),
    },
    $transaction: jest.fn((ps: Promise<unknown>[]) => Promise.all(ps)),
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
  return { service, store, mirror };
}

afterEach(() => {
  delete process.env.BUYLEDGER_FIXED_NOW;
});

describe('OrdersService lookup cascade (element-level, task 2.10)', () => {
  it('renames only the affected category element, leaving disjoint additions intact', async () => {
    const { service, store } = makeService([makeRow({ categories: ['Food', 'Gifts'] })]);
    await service.cascadeRenameCategory('U1', 'Food', 'Snacks');
    expect(store.get('ORD1')!.categories).toEqual(['Snacks', 'Gifts']);
  });

  it('strips a deleted category element without dropping concurrent disjoint additions', async () => {
    const { service, store } = makeService([makeRow({ categories: ['Food', 'Gifts'] })]);
    await service.cascadeStripCategory('U1', 'Food');
    expect(store.get('ORD1')!.categories).toEqual(['Gifts']);
  });

  it('strips a deleted orderSource scalar (clears the reference) so it is not orphaned', async () => {
    const { service, store } = makeService([makeRow({ orderSource: '蝦皮' })]);
    await service.cascadeStripScalar('U1', 'orderSource', '蝦皮');
    expect(store.get('ORD1')!.orderSource).toBe('');
  });

  it('does not touch orders that do not reference the deleted lookup', async () => {
    const { service, store } = makeService([
      makeRow({ id: 'A', categories: ['Food'] }),
      makeRow({ id: 'B', categories: ['Beauty'] }),
    ]);
    await service.cascadeStripCategory('U1', 'Food');
    expect(store.get('A')!.categories).toEqual([]);
    expect(store.get('B')!.categories).toEqual(['Beauty']);
  });
});

describe('OrdersService cascade does not resurrect tombstones (C1)', () => {
  it('scalar rename skips a tombstoned order: never re-mirrors it as a live (_deleted:false) doc', async () => {
    const tomb = makeRow({
      id: 'DEAD',
      orderSource: '蝦皮',
      deletedAt: new Date(FIXED_ISO),
      deleteClock: enc(5000, 0, 'server'),
    });
    const { service, mirror, store } = makeService([tomb]);
    await service.cascadeRenameScalar('U1', 'orderSource', '蝦皮', '蝦皮購物');
    expect(store.get('DEAD')!.orderSource).toBe('蝦皮');
    // mirrorOrder 會寫 _deleted:false 整份覆蓋、復活 tombstone，故不得呼叫
    expect(mirror.mirrorOrder).not.toHaveBeenCalled();
  });

  it('array rename skips a tombstoned order: leaves its array untouched and does not re-mirror it live', async () => {
    const tomb = makeRow({
      id: 'DEAD',
      categories: ['Food', 'Gifts'],
      deletedAt: new Date(FIXED_ISO),
      deleteClock: enc(5000, 0, 'server'),
    });
    const { service, mirror, store } = makeService([tomb]);
    await service.cascadeRenameCategory('U1', 'Food', 'Snacks');
    expect(store.get('DEAD')!.categories).toEqual(['Food', 'Gifts']);
    expect(mirror.mirrorOrder).not.toHaveBeenCalled();
  });
});

describe('OrdersService cascade stamps server field clocks (W5)', () => {
  it('scalar rename bumps the field clock so a stale-clock client write cannot revert the authoritative rename', async () => {
    const row = makeRow({
      id: 'ORD1',
      orderSource: '蝦皮',
      // 既有欄位 clock 偏低，
      // 供下方驗證 cascade 推進後能壓制 stale-clock client 寫入
      fieldClocks: { orderSource: enc(100, 0, 'device-a') },
    });
    const { service, store } = makeService([row]);
    await service.cascadeRenameScalar('U1', 'orderSource', '蝦皮', '蝦皮購物');
    expect(store.get('ORD1')!.orderSource).toBe('蝦皮購物');

    // cascade 後欄位 clock 已被 server HLC 推進
    const stampedEnc = (store.get('ORD1')!.fieldClocks as Record<string, string>).orderSource;
    expect(stampedEnc).toBeDefined();
    expect(stampedEnc > enc(100, 0, 'device-a')).toBe(true);

    // 舊 clock (1500) client 寫入改不回舊名，cascade 值存活
    await service.patch('U1', 'ORD1', {
      changedFields: { orderSource: '蝦皮' },
      fieldClocks: { orderSource: enc(1500, 0, 'device-a') },
    });
    expect(store.get('ORD1')!.orderSource).toBe('蝦皮購物');
  });
});
