// 載入 OrdersService 會經由 FirestoreMirrorService 連帶 import firebase-admin (ESM jose)，需 mock。
jest.mock('firebase-admin/app', () => ({
  initializeApp: jest.fn(),
  getApps: jest.fn(() => []),
  cert: jest.fn(),
}));
jest.mock('firebase-admin/auth', () => ({ getAuth: jest.fn() }));
jest.mock('firebase-admin/firestore', () => ({ getFirestore: jest.fn() }));
jest.mock('firebase-admin/storage', () => ({ getStorage: jest.fn() }));

import { NotFoundException } from '@nestjs/common';
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
    const service = new OrdersService(prisma as never, now as never, ids as never, mirror as never);
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
