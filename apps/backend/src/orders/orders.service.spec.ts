// 載入 OrdersService 會經由 FirestoreMirrorService 連帶 import firebase-admin (ESM jose)，需 mock。
jest.mock('firebase-admin/app', () => ({
  initializeApp: jest.fn(),
  getApps: jest.fn(() => []),
  cert: jest.fn(),
}));
jest.mock('firebase-admin/auth', () => ({ getAuth: jest.fn() }));
jest.mock('firebase-admin/firestore', () => ({ getFirestore: jest.fn() }));
jest.mock('firebase-admin/storage', () => ({ getStorage: jest.fn() }));

import { BadRequestException, NotFoundException } from '@nestjs/common';
import { OrdersService } from './orders.service';

// 對齊 spec「Reads are scoped to the caller's uid」「Writes target only records owned by the caller」
// 「Domain entities are owned by a single user」：所有讀寫一律按 ownerUid 圈，跨使用者隔離。
describe('OrdersService uid scoping', () => {
  function makeService(overrides: Record<string, unknown> = {}) {
    const prisma = {
      order: {
        findMany: jest.fn().mockResolvedValue([]),
        findFirst: jest.fn().mockResolvedValue(null),
        count: jest.fn().mockResolvedValue(0),
        create: jest.fn((args: { data: Record<string, unknown> }) => Promise.resolve(args.data)),
        update: jest.fn(),
        delete: jest.fn(),
        updateMany: jest.fn(),
      },
      paymentMethod: {
        findUnique: jest.fn().mockResolvedValue(null),
        findMany: jest.fn().mockResolvedValue([]),
      },
      $transaction: jest.fn((ps: Promise<unknown>[]) => Promise.all(ps)),
      ...overrides,
    };
    const now = { now: () => new Date('2026-06-14T00:00:00.000Z') };
    const ids = { uuid: () => 'uuid-1', newOrderId: () => 'BL-NEW' };
    const mirror = {
      mirrorOrder: jest.fn().mockResolvedValue(undefined),
      upsert: jest.fn().mockResolvedValue(undefined),
      remove: jest.fn().mockResolvedValue(undefined),
    };
    const service = new OrdersService(prisma as never, now as never, ids as never, mirror as never, {} as never);
    return { service, prisma };
  }

  it('list scopes findMany by the caller ownerUid', async () => {
    const { service, prisma } = makeService();
    await service.list('user-A');
    expect(prisma.order.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { ownerUid: 'user-A' } }),
    );
  });

  it('get of an order not owned by the caller throws NotFound', async () => {
    const { service, prisma } = makeService();
    await expect(service.get('user-A', 'BL-x')).rejects.toBeInstanceOf(NotFoundException);
    expect(prisma.order.findFirst).toHaveBeenCalledWith({
      where: { id: 'BL-x', ownerUid: 'user-A' },
    });
  });

  it('remove of an order not owned by the caller throws NotFound and never deletes', async () => {
    const { service, prisma } = makeService();
    await expect(service.remove('user-A', 'BL-x')).rejects.toBeInstanceOf(NotFoundException);
    expect(prisma.order.count).toHaveBeenCalledWith({ where: { id: 'BL-x', ownerUid: 'user-A' } });
    expect(prisma.order.delete).not.toHaveBeenCalled();
  });

  it('create stamps the caller uid as the record ownerUid', async () => {
    const { service, prisma } = makeService();
    await service.create('user-A', {} as never);
    const data = (prisma.order.create as jest.Mock).mock.calls[0][0].data;
    expect(data.ownerUid).toBe('user-A');
  });
});

// 對齊 spec「Backend batch status endpoint is owner-scoped and re-mirrors Firestore」：
// 批次更新一律按 ownerUid 圈、拒絕 merged 目標、更新後 remirror 受影響訂單。
describe('OrdersService batchSetStatus', () => {
  // 構造一筆可被 rowToDto 處理的最小有效 Prisma 列。
  function makeRow(id: string, status = 'shipping') {
    return {
      id,
      ownerUid: 'user-A',
      customerName: '客戶',
      customerInitials: 'C',
      customerTier: 'new',
      status,
      currency: 'TWD',
      date: new Date('2026-06-14T00:00:00.000Z'),
      items: [],
      itemCost: '0',
      domesticShipping: '0',
      internationalShipping: '0',
      foreignDomesticShipping: '0',
      cardFeeRate: '0',
      platformFeeRate: '0',
      paymentFeeRate: '0',
      chargedAmount: '0',
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
    };
  }

  function makeService(overrides: Record<string, unknown> = {}) {
    const prisma = {
      order: {
        updateMany: jest.fn().mockResolvedValue({ count: 0 }),
        findMany: jest.fn().mockResolvedValue([]),
        ...((overrides.order as Record<string, unknown>) ?? {}),
      },
    };
    const now = { now: () => new Date('2026-06-14T00:00:00.000Z') };
    const ids = { uuid: () => 'uuid-1', newOrderId: () => 'BL-NEW' };
    const mirror = {
      mirrorOrder: jest.fn().mockResolvedValue(undefined),
      upsert: jest.fn().mockResolvedValue(undefined),
      remove: jest.fn().mockResolvedValue(undefined),
    };
    const service = new OrdersService(prisma as never, now as never, ids as never, mirror as never, {} as never);
    return { service, prisma, mirror };
  }

  it('updates only the caller ownerUid orders via a single updateMany', async () => {
    const { service, prisma } = makeService();
    await service.batchSetStatus('user-A', { ids: ['BL-1', 'BL-2'], status: 'arrived' });
    expect(prisma.order.updateMany).toHaveBeenCalledTimes(1);
    expect(prisma.order.updateMany).toHaveBeenCalledWith({
      where: { id: { in: ['BL-1', 'BL-2'] }, ownerUid: 'user-A' },
      data: { status: 'arrived' },
    });
  });

  it('rejects merged as a target and never updates', async () => {
    const { service, prisma } = makeService();
    await expect(
      service.batchSetStatus('user-A', { ids: ['BL-1'], status: 'merged' }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.order.updateMany).not.toHaveBeenCalled();
  });

  it('rejects an invalid status and never updates', async () => {
    const { service, prisma } = makeService();
    await expect(
      service.batchSetStatus('user-A', { ids: ['BL-1'], status: 'bogus' as never }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.order.updateMany).not.toHaveBeenCalled();
  });

  it('with empty ids returns [] and never calls updateMany', async () => {
    const { service, prisma } = makeService();
    const result = await service.batchSetStatus('user-A', { ids: [], status: 'arrived' });
    expect(result).toEqual([]);
    expect(prisma.order.updateMany).not.toHaveBeenCalled();
  });

  it('re-mirrors each affected order after the batch update', async () => {
    const rows = [makeRow('BL-1', 'arrived'), makeRow('BL-2', 'arrived')];
    const { service, mirror, prisma } = makeService({
      order: {
        updateMany: jest.fn().mockResolvedValue({ count: 2 }),
        findMany: jest.fn().mockResolvedValue(rows),
      },
    });
    const result = await service.batchSetStatus('user-A', {
      ids: ['BL-1', 'BL-2'],
      status: 'arrived',
    });
    expect(prisma.order.findMany).toHaveBeenCalledWith({
      where: { id: { in: ['BL-1', 'BL-2'] }, ownerUid: 'user-A' },
    });
    expect(mirror.mirrorOrder).toHaveBeenCalledTimes(2);
    expect(result).toHaveLength(2);
    expect(result.map((o) => o.id)).toEqual(['BL-1', 'BL-2']);
  });
});
