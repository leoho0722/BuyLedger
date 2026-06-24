// 載入 OrdersService 會經由 FirestoreMirrorService 連帶 import firebase-admin
// (ESM jose)，需 mock
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

// 以毫秒級 p 編碼 (padStart 對齊 HLC 編碼)
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
    mirrorDirty: false,
    mirrorPendingSinceClock: null,
    ...over,
  };
}

function makeService(
  initial?: Record<string, unknown>[],
  opts?: { newOrderId?: () => string },
) {
  const store = new Map<string, Record<string, unknown>>();
  for (const row of initial ?? []) store.set(row.id as string, row);

  const prisma = {
    order: {
      findFirst: jest.fn(async ({ where }: { where: Record<string, unknown> }) => {
        const row = store.get(where.id as string);
        if (!row || row.ownerUid !== where.ownerUid) return null;
        if (where.deletedAt === null && row.deletedAt) return null;
        return row;
      }),
      findMany: jest.fn(async ({ where }: { where: Record<string, unknown> }) => {
        const ids = (where.id as { in?: string[] } | undefined)?.in;
        const out: Record<string, unknown>[] = [];
        for (const row of store.values()) {
          if (where.ownerUid && row.ownerUid !== where.ownerUid) continue;
          if (ids && !ids.includes(row.id as string)) continue;
          if (where.deletedAt === null && row.deletedAt) continue;
          out.push(row);
        }
        return out;
      }),
      findUnique: jest.fn(async ({ where }: { where: { id: string } }) => store.get(where.id) ?? null),
      count: jest.fn(async ({ where }: { where: Record<string, unknown> }) => {
        const row = store.get(where.id as string);
        return row && row.ownerUid === where.ownerUid ? 1 : 0;
      }),
      create: jest.fn(async ({ data }: { data: Record<string, unknown> }) => {
        store.set(data.id as string, { ...data });
        return store.get(data.id as string);
      }),
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
      deleteMany: jest.fn(async ({ where }: { where: { deletedAt?: { lt?: Date } } }) => {
        let count = 0;
        for (const [id, row] of [...store.entries()]) {
          const lt = where.deletedAt?.lt;
          if (row.deletedAt && lt && (row.deletedAt as Date) < lt) {
            store.delete(id);
            count++;
          }
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
  // server 生成 id 故意異於 seed merge id，才能讓重生 id 的短路 bug 暴露
  const ids = { uuid: () => 'uuid-x', newOrderId: opts?.newOrderId ?? (() => 'BL-SERVER') };
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

describe('OrdersService delete tombstone', () => {
  it('soft-deletes via a delete patch: sets deletedAt + deleteClock, keeps the row, mirrors a tombstone', async () => {
    const { service, mirror, store } = makeService([makeRow()]);
    const res = await service.patch('U1', 'ORD1', { delete: { clock: enc(1800, 0, 'device-a') } });
    expect(res.order.id).toBe('ORD1');
    const row = store.get('ORD1')!;
    expect(row.deletedAt).not.toBeNull();
    expect(row.deleteClock).toBe(enc(1800, 0, 'device-a'));
    expect(mirror.mirrorOrderTombstone).toHaveBeenCalledWith(
      'U1',
      expect.objectContaining({ id: 'ORD1' }),
      enc(1800, 0, 'device-a'),
      expect.objectContaining({ writerId: 'server' }),
    );
    // 軟刪除後 list / get 排除
    await expect(service.get('U1', 'ORD1')).rejects.toBeTruthy();
    expect(await service.list('U1')).toEqual([]);
  });

  it('remove() soft-deletes with a server-generated deleteClock and keeps the row', async () => {
    const { service, mirror, store } = makeService([makeRow()]);
    await service.remove('U1', 'ORD1');
    const row = store.get('ORD1')!;
    expect(row.deletedAt).not.toBeNull();
    expect(String(row.deleteClock)).toMatch(/:server$/);
    expect(mirror.mirrorOrderTombstone).toHaveBeenCalled();
    expect(mirror.remove).not.toHaveBeenCalled();
  });
});

describe('OrdersService resurrection (Option A, p→c→w)', () => {
  // delete@1800 vs edit amount@2000 → 復活並保留 customerName/note、amount 疊上
  it('resurrects when an incoming field clock is strictly greater than the deleteClock, preserving untouched fields', async () => {
    const storedClocks = {
      customerName: enc(1000, 0, 'device-a'),
      notes: enc(1000, 0, 'device-a'),
      chargedAmount: enc(1000, 0, 'device-a'),
    };
    const deleted = makeRow({
      customerName: '王小明',
      notes: '備註內容',
      chargedAmount: '100',
      fieldClocks: storedClocks,
      deletedAt: new Date(FIXED_ISO),
      deleteClock: enc(1800, 0, 'device-a'),
    });
    const { service, store } = makeService([deleted]);
    const res = await service.patch('U1', 'ORD1', {
      changedFields: { chargedAmount: '2000' },
      fieldClocks: { chargedAmount: enc(2000, 0, 'device-b') },
    });
    expect(res.order.chargedAmount).toBe('2000');
    // 未觸及欄位保留 stored 值
    expect(res.order.customer.name).toBe('王小明');
    expect(res.order.notes).toBe('備註內容');
    // 復活：清 deletedAt / deleteClock，列重新可讀
    const row = store.get('ORD1')!;
    expect(row.deletedAt).toBeNull();
    expect(row.deleteClock).toBe('');
    expect((await service.list('U1')).map((o) => o.id)).toEqual(['ORD1']);
  });

  it('stays deleted when the deleteClock is greater than or equal to every incoming clock', async () => {
    const deleted = makeRow({
      customerName: '王小明',
      notes: '備註內容',
      chargedAmount: '100',
      fieldClocks: {
        customerName: enc(1000, 0, 'device-a'),
        notes: enc(1000, 0, 'device-a'),
        chargedAmount: enc(1000, 0, 'device-a'),
      },
      deletedAt: new Date(FIXED_ISO),
      deleteClock: enc(2500, 0, 'device-a'),
    });
    const { service, mirror, store } = makeService([deleted]);
    await service.patch('U1', 'ORD1', {
      changedFields: { chargedAmount: '2000' },
      fieldClocks: { chargedAmount: enc(2000, 0, 'device-b') },
    });
    const row = store.get('ORD1')!;
    expect(row.deletedAt).not.toBeNull();
    expect(row.deleteClock).toBe(enc(2500, 0, 'device-a'));
    // 仍 tombstone：讀取排除、鏡像仍為 tombstone
    expect(await service.list('U1')).toEqual([]);
    expect(mirror.mirrorOrderTombstone).toHaveBeenCalled();
    expect(mirror.mirrorOrder).not.toHaveBeenCalled();
  });

  // 復活須比 incoming 原始 fieldClocks 與 deleteClock，
  // 不可用會 fallback 成 stored clock 的 appliedClocks (否則落敗寫入誤判復活)
  it('stays deleted when a losing write has an incoming clock below deleteClock even though stored clock exceeds it', async () => {
    const deleted = makeRow({
      chargedAmount: '100',
      // stored chargedAmount clock = 2200 > deleteClock (2000) > incoming (1500)
      fieldClocks: { chargedAmount: enc(2200, 0, 'device-a') },
      deletedAt: new Date(FIXED_ISO),
      deleteClock: enc(2000, 0, 'server'),
    });
    const { service, mirror, store } = makeService([deleted]);
    await service.patch('U1', 'ORD1', {
      changedFields: { chargedAmount: '2000' },
      fieldClocks: { chargedAmount: enc(1500, 0, 'device-b') },
    });
    const row = store.get('ORD1')!;
    // incoming (1500) < deleteClock (2000) → 維持刪除
    // (不因 stored clock 2200>2000 誤判復活)
    expect(row.deletedAt).not.toBeNull();
    expect(row.deleteClock).toBe(enc(2000, 0, 'server'));
    // stored 值較高 clock 勝出 → 仍是 '100'，incoming '2000' 落敗
    expect(String(row.chargedAmount)).toBe('100');
    expect(await service.list('U1')).toEqual([]);
    expect(mirror.mirrorOrderTombstone).toHaveBeenCalled();
    expect(mirror.mirrorOrder).not.toHaveBeenCalled();
  });

  // 列有 deletedAt 但 deleteClock 為空字串 (畸形硬 tombstone)，
  // 不可被任何 patch 免費復活
  it('does not resurrect a malformed tombstone whose deleteClock is empty', async () => {
    const malformed = makeRow({
      chargedAmount: '100',
      fieldClocks: { chargedAmount: enc(1000, 0, 'device-a') },
      deletedAt: new Date(FIXED_ISO),
      deleteClock: '',
    });
    const { service, mirror, store } = makeService([malformed]);
    await service.patch('U1', 'ORD1', {
      changedFields: { chargedAmount: '2000' },
      fieldClocks: { chargedAmount: enc(9000, 0, 'device-b') },
    });
    const row = store.get('ORD1')!;
    expect(row.deletedAt).not.toBeNull();
    expect(await service.list('U1')).toEqual([]);
    // 維持刪除：以 tombstone 重寫鏡像、不寫活文件
    expect(mirror.mirrorOrderTombstone).toHaveBeenCalled();
    expect(mirror.mirrorOrder).not.toHaveBeenCalled();
  });
});

describe('OrdersService status sticky-merged', () => {
  it('ignores a status field in a normal patch (cannot set merged, cannot change away from merged)', async () => {
    const { service, store } = makeService([
      makeRow({ status: 'merged', fieldClocks: { status: enc(1000, 0, 'server') } }),
    ]);
    const res = await service.patch('U1', 'ORD1', {
      changedFields: { status: 'quoting', notes: 'x' },
      fieldClocks: { status: enc(9000, 0, 'device-b'), notes: enc(9000, 0, 'device-b') },
    });
    expect(res.order.status).toBe('merged');
    expect(res.order.notes).toBe('x');
    expect(store.get('ORD1')!.status).toBe('merged');
  });
});

describe('OrdersService photo union merge', () => {
  it('unions photos by content hash so concurrent additions from two devices both survive', async () => {
    const stored = makeRow({
      photos: ['QUJD'],
      fieldClocks: { photos: enc(1000, 0, 'device-a') },
    });
    const { service } = makeService([stored]);
    const res = await service.patch('U1', 'ORD1', {
      changedFields: { photos: ['WFla'] },
      fieldClocks: { photos: enc(2000, 0, 'device-b') },
    });
    // 聯集：stored 'QUJD' 與 incoming 'WFla' 皆保留 (內容不同雜湊不同)
    expect(res.order.photos.sort()).toEqual(['QUJD', 'WFla']);
  });

  it('does not duplicate identical photo content across stored and incoming', async () => {
    const stored = makeRow({
      photos: ['QUJD'],
      fieldClocks: { photos: enc(1000, 0, 'device-a') },
    });
    const { service } = makeService([stored]);
    const res = await service.patch('U1', 'ORD1', {
      changedFields: { photos: ['QUJD'] },
      fieldClocks: { photos: enc(2000, 0, 'device-b') },
    });
    expect(res.order.photos).toEqual(['QUJD']);
  });

  // stored photos clock 較高時 union 仍須跑，
  // 否則 incoming 新照片被時鐘門檻吞掉；clock 取兩端 max
  it('still unions new photos even when the stored photo clock is higher than incoming', async () => {
    const stored = makeRow({
      photos: ['QUJD'],
      // stored photos clock (3000) > incoming (2000)：
      // 舊邏輯會整個跳過 union、丟掉 incoming 新照片
      fieldClocks: { photos: enc(3000, 0, 'device-a') },
    });
    const { service, store } = makeService([stored]);
    const res = await service.patch('U1', 'ORD1', {
      changedFields: { photos: ['WFla'] },
      fieldClocks: { photos: enc(2000, 0, 'device-b') },
    });
    // 兩端各自新增的不同照片皆存活 (union)
    expect([...res.order.photos].sort()).toEqual(['QUJD', 'WFla']);
    // photos 欄位 clock 取兩端 max (3000)，
    // 使聯集值在投影傳播、不停在較低 incoming clock
    expect((store.get('ORD1')!.fieldClocks as Record<string, string>).photos).toBe(
      enc(3000, 0, 'device-a'),
    );
  });
});

describe('OrdersService direct-write mirror keeps the projection envelope (W4)', () => {
  it('setStatus mirrors with the field-clock envelope so _fieldClocks survives the .set overwrite', async () => {
    const row = makeRow({
      fieldClocks: { status: enc(1000, 0, 'device-a'), notes: enc(900, 0, 'device-a') },
    });
    const { service, mirror } = makeService([row]);
    await service.setStatus('U1', 'ORD1', { status: 'arrived' });
    expect(mirror.mirrorOrder).toHaveBeenCalledWith(
      'U1',
      expect.objectContaining({ id: 'ORD1' }),
      expect.objectContaining({
        writerId: 'server',
        fieldClocks: expect.objectContaining({ status: enc(1000, 0, 'device-a') }),
      }),
    );
  });

  it('remirror (via cascade) of a live row carries the field-clock envelope and a live (not tombstone) mirror', async () => {
    const row = makeRow({
      orderSource: '蝦皮',
      fieldClocks: { orderSource: enc(1000, 0, 'device-a') },
    });
    const { service, mirror } = makeService([row]);
    await service.cascadeRenameScalar('U1', 'orderSource', '蝦皮', '蝦皮購物');
    expect(mirror.mirrorOrder).toHaveBeenCalledWith(
      'U1',
      expect.objectContaining({ id: 'ORD1' }),
      expect.objectContaining({ writerId: 'server', fieldClocks: expect.any(Object) }),
    );
    const calls = mirror.mirrorOrder.mock.calls as unknown as unknown[][];
    const meta = calls[0][2] as { fieldClocks: Record<string, string> };
    expect(meta.fieldClocks.orderSource).toBeDefined();
  });
});

describe('OrdersService remirror keeps tombstones tombstoned (C1)', () => {
  it('remirrors a tombstoned merge source as a tombstone, never as a live (_deleted:false) doc', async () => {
    // 來源已是 tombstone 時 remirror 須走 mirrorOrderTombstone，
    // 不可整份 .set 覆蓋成 _deleted:false 而復活
    const tombSource = makeRow({
      id: 'A',
      status: 'arrived',
      fieldClocks: { status: enc(5, 0, 'device-a') },
      deletedAt: new Date(FIXED_ISO),
      deleteClock: enc(7000, 0, 'server'),
    });
    const { service, mirror } = makeService([tombSource]);
    await service.create('U1', {
      id: 'BL-CLIENT',
      mergedSourceIDs: ['A'],
      customer: { name: '王' },
      currency: 'TWD',
    });
    // 來源 A 為 tombstone：remirror 須以 tombstone 形式 (mirrorOrderTombstone)
    const aLiveMirror = mirror.mirrorOrder.mock.calls.some(
      (c: unknown[]) => (c[1] as { id: string }).id === 'A',
    );
    const aTombMirror = mirror.mirrorOrderTombstone.mock.calls.some(
      (c: unknown[]) => (c[1] as { id: string }).id === 'A',
    );
    expect(aLiveMirror).toBe(false);
    expect(aTombMirror).toBe(true);
  });
});

describe('OrdersService merge-create idempotency (lost-ack)', () => {
  // merge 翻 A/B 為 merged@10、A 後改回 active@12；
  // 重送 merge-create 須短路、A 維持 active@12
  it('short-circuits a resent merge-create and does not revert a later source edit', async () => {
    const sourceA = makeRow({
      id: 'A',
      status: 'arrived',
      fieldClocks: { status: enc(12, 0, 'device-b') },
    });
    const sourceB = makeRow({ id: 'B', status: 'merged', fieldClocks: { status: enc(10, 0, 'server') } });
    // server 生成 id 故意異於 client id，
    // 讓「重生 id→findFirst 不命中→重複 create」的舊行為暴露
    const existingM = makeRow({ id: 'BL-CLIENT', mergedSourceIDs: ['A', 'B'] });
    const { service, prisma, store } = makeService([sourceA, sourceB, existingM]);

    const res = await service.create('U1', {
      id: 'BL-CLIENT',
      mergedSourceIDs: ['A', 'B'],
      customer: { name: '王' },
      currency: 'TWD',
    });

    // 重送保留 client id 並以 (ownerUid,id) 短路：
    // 回傳同一列、不重複插入、不對來源翻 merged
    expect(res.id).toBe('BL-CLIENT');
    expect(prisma.order.create).not.toHaveBeenCalled();
    // A 維持後來的 active 狀態 (arrived@12)，未被回退成 merged
    expect(store.get('A')!.status).toBe('arrived');
  });

  it('clock-guards source merged flip: a source with a later status clock is not reverted', async () => {
    // 來源 A 的 status 欄位時鐘晚於 mergeClock
    // (server 起始於 fixed now → 1704067200000)
    const lateClock = enc(1704067200000 + 10_000, 0, 'device-b');
    const sourceA = makeRow({ id: 'A', status: 'arrived', fieldClocks: { status: lateClock } });
    const { service, store } = makeService([sourceA]);

    await service.create('U1', {
      id: 'BL-MERGED',
      mergedSourceIDs: ['A'],
      customer: { name: '王' },
      currency: 'TWD',
    });

    // mergeClock ≤ 來源 status 欄位時鐘 → 保留來源較晚狀態、不翻 merged
    expect(store.get('A')!.status).toBe('arrived');
  });
});

describe('OrdersService tombstone purge', () => {
  it('purges tombstones older than the retention window', async () => {
    const oldDeleted = makeRow({
      id: 'OLD',
      deletedAt: new Date('2023-01-01T00:00:00.000Z'),
      deleteClock: enc(1, 0, 'server'),
    });
    const recentDeleted = makeRow({
      id: 'RECENT',
      deletedAt: new Date(FIXED_ISO),
      deleteClock: enc(2, 0, 'server'),
    });
    const { service, store } = makeService([oldDeleted, recentDeleted]);
    const purged = await service.purgeExpiredTombstones();
    expect(purged).toBe(1);
    expect(store.has('OLD')).toBe(false);
    expect(store.has('RECENT')).toBe(true);
  });
});
