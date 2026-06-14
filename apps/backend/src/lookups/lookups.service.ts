import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { FirestoreMirrorService } from '../firebase/firestore-mirror.service';
import { OrdersService } from '../orders/orders.service';

export interface PaymentMethodDTO {
  name: string;
  isCardless: boolean;
  isBankTransfer: boolean;
  isCashOnDelivery: boolean;
}

export interface PaymentMethodInput {
  name?: string;
  isCardless?: boolean;
  isBankTransfer?: boolean;
  isCashOnDelivery?: boolean;
}

export interface NameInput {
  name?: string;
}

@Injectable()
export class LookupsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly orders: OrdersService,
    private readonly mirror: FirestoreMirrorService,
  ) {}

  // MARK: - 商品類別

  async listCategories(uid: string): Promise<string[]> {
    const rows = await this.prisma.category.findMany({
      where: { ownerUid: uid },
      orderBy: { name: 'asc' },
    });
    return rows.map((r) => r.name);
  }

  async addCategory(uid: string, name: string): Promise<string[]> {
    const n = requireName(name);
    await this.prisma.category.upsert({
      where: { ownerUid_name: { ownerUid: uid, name: n } },
      create: { ownerUid: uid, name: n },
      update: {},
    });
    await this.mirror.upsert(uid, 'categories', n, { name: n });
    return this.listCategories(uid);
  }

  async renameCategory(uid: string, oldName: string, newName: string): Promise<string[]> {
    const n = requireName(newName);
    await this.ensureExists('category', uid, oldName);
    if (n !== oldName) {
      await this.assertFree('category', uid, n);
      await this.orders.cascadeRenameCategory(uid, oldName, n);
      await this.prisma.$transaction([
        this.prisma.category.create({ data: { ownerUid: uid, name: n } }),
        this.prisma.category.delete({ where: { ownerUid_name: { ownerUid: uid, name: oldName } } }),
      ]);
      await this.mirror.remove(uid, 'categories', oldName);
      await this.mirror.upsert(uid, 'categories', n, { name: n });
    }
    return this.listCategories(uid);
  }

  async removeCategory(uid: string, name: string): Promise<string[]> {
    await this.prisma.category.deleteMany({ where: { ownerUid: uid, name } });
    await this.mirror.remove(uid, 'categories', name);
    return this.listCategories(uid);
  }

  // MARK: - 訂單來源

  async listOrderSources(uid: string): Promise<string[]> {
    const rows = await this.prisma.orderSource.findMany({
      where: { ownerUid: uid },
      orderBy: { name: 'asc' },
    });
    return rows.map((r) => r.name);
  }

  async addOrderSource(uid: string, name: string): Promise<string[]> {
    const n = requireName(name);
    await this.prisma.orderSource.upsert({
      where: { ownerUid_name: { ownerUid: uid, name: n } },
      create: { ownerUid: uid, name: n },
      update: {},
    });
    await this.mirror.upsert(uid, 'orderSources', n, { name: n });
    return this.listOrderSources(uid);
  }

  async renameOrderSource(uid: string, oldName: string, newName: string): Promise<string[]> {
    const n = requireName(newName);
    await this.ensureExists('orderSource', uid, oldName);
    if (n !== oldName) {
      await this.assertFree('orderSource', uid, n);
      await this.orders.cascadeRenameScalar(uid, 'orderSource', oldName, n);
      await this.prisma.$transaction([
        this.prisma.orderSource.create({ data: { ownerUid: uid, name: n } }),
        this.prisma.orderSource.delete({ where: { ownerUid_name: { ownerUid: uid, name: oldName } } }),
      ]);
      await this.mirror.remove(uid, 'orderSources', oldName);
      await this.mirror.upsert(uid, 'orderSources', n, { name: n });
    }
    return this.listOrderSources(uid);
  }

  async removeOrderSource(uid: string, name: string): Promise<string[]> {
    await this.prisma.orderSource.deleteMany({ where: { ownerUid: uid, name } });
    await this.mirror.remove(uid, 'orderSources', name);
    return this.listOrderSources(uid);
  }

  // MARK: - 對帳狀態

  async listVerificationStatuses(uid: string): Promise<string[]> {
    const rows = await this.prisma.verificationStatus.findMany({
      where: { ownerUid: uid },
      orderBy: { name: 'asc' },
    });
    return rows.map((r) => r.name);
  }

  async addVerificationStatus(uid: string, name: string): Promise<string[]> {
    const n = requireName(name);
    await this.prisma.verificationStatus.upsert({
      where: { ownerUid_name: { ownerUid: uid, name: n } },
      create: { ownerUid: uid, name: n },
      update: {},
    });
    await this.mirror.upsert(uid, 'verificationStatuses', n, { name: n });
    return this.listVerificationStatuses(uid);
  }

  async renameVerificationStatus(uid: string, oldName: string, newName: string): Promise<string[]> {
    const n = requireName(newName);
    await this.ensureExists('verificationStatus', uid, oldName);
    if (n !== oldName) {
      await this.assertFree('verificationStatus', uid, n);
      await this.orders.cascadeRenameScalar(uid, 'verificationStatus', oldName, n);
      await this.prisma.$transaction([
        this.prisma.verificationStatus.create({ data: { ownerUid: uid, name: n } }),
        this.prisma.verificationStatus.delete({
          where: { ownerUid_name: { ownerUid: uid, name: oldName } },
        }),
      ]);
      await this.mirror.remove(uid, 'verificationStatuses', oldName);
      await this.mirror.upsert(uid, 'verificationStatuses', n, { name: n });
    }
    return this.listVerificationStatuses(uid);
  }

  async removeVerificationStatus(uid: string, name: string): Promise<string[]> {
    await this.prisma.verificationStatus.deleteMany({ where: { ownerUid: uid, name } });
    await this.mirror.remove(uid, 'verificationStatuses', name);
    return this.listVerificationStatuses(uid);
  }

  // MARK: - 付款方式 (帶旗標)

  async listPaymentMethods(uid: string): Promise<PaymentMethodDTO[]> {
    const rows = await this.prisma.paymentMethod.findMany({
      where: { ownerUid: uid },
      orderBy: { name: 'asc' },
    });
    return rows.map((r) => ({
      name: r.name,
      isCardless: r.isCardless,
      isBankTransfer: r.isBankTransfer,
      isCashOnDelivery: r.isCashOnDelivery,
    }));
  }

  async addPaymentMethod(uid: string, input: PaymentMethodInput): Promise<PaymentMethodDTO[]> {
    const n = requireName(input.name);
    const flags = {
      isCardless: input.isCardless ?? false,
      isBankTransfer: input.isBankTransfer ?? false,
      isCashOnDelivery: input.isCashOnDelivery ?? false,
    };
    await this.prisma.paymentMethod.upsert({
      where: { ownerUid_name: { ownerUid: uid, name: n } },
      create: { ownerUid: uid, name: n, ...flags },
      update: { ...flags },
    });
    await this.mirror.upsert(uid, 'paymentMethods', n, { name: n, ...flags });
    return this.listPaymentMethods(uid);
  }

  // 編輯付款方式：改名 (cascade) 並把三旗標設成「使用者選擇的確切值」(含清除既有旗標)。
  async updatePaymentMethod(
    uid: string,
    oldName: string,
    input: PaymentMethodInput,
  ): Promise<PaymentMethodDTO[]> {
    const existing = await this.prisma.paymentMethod.findUnique({
      where: { ownerUid_name: { ownerUid: uid, name: oldName } },
    });
    if (!existing) throw new NotFoundException(`找不到付款方式 ${oldName}`);
    const n = requireName(input.name ?? oldName);

    const flags = {
      isCardless: input.isCardless ?? false,
      isBankTransfer: input.isBankTransfer ?? false,
      isCashOnDelivery: input.isCashOnDelivery ?? false,
    };

    if (n !== oldName) {
      const clash = await this.prisma.paymentMethod.findUnique({
        where: { ownerUid_name: { ownerUid: uid, name: n } },
      });
      if (clash) throw new BadRequestException('名稱已存在');
      await this.orders.cascadeRenameScalar(uid, 'paymentMethod', oldName, n);
      await this.prisma.$transaction([
        this.prisma.paymentMethod.create({ data: { ownerUid: uid, name: n, ...flags } }),
        this.prisma.paymentMethod.delete({
          where: { ownerUid_name: { ownerUid: uid, name: oldName } },
        }),
      ]);
      await this.mirror.remove(uid, 'paymentMethods', oldName);
      await this.mirror.upsert(uid, 'paymentMethods', n, { name: n, ...flags });
    } else {
      await this.prisma.paymentMethod.update({
        where: { ownerUid_name: { ownerUid: uid, name: oldName } },
        data: flags,
      });
      await this.mirror.upsert(uid, 'paymentMethods', oldName, { name: oldName, ...flags });
    }
    return this.listPaymentMethods(uid);
  }

  async removePaymentMethod(uid: string, name: string): Promise<PaymentMethodDTO[]> {
    await this.prisma.paymentMethod.deleteMany({ where: { ownerUid: uid, name } });
    await this.mirror.remove(uid, 'paymentMethods', name);
    return this.listPaymentMethods(uid);
  }

  // MARK: - 私有

  private async ensureExists(
    model: 'category' | 'orderSource' | 'verificationStatus',
    uid: string,
    name: string,
  ): Promise<void> {
    const count = await (this.prisma[model] as any).count({ where: { ownerUid: uid, name } });
    if (count === 0) throw new NotFoundException(`找不到 ${name}`);
  }

  private async assertFree(
    model: 'category' | 'orderSource' | 'verificationStatus',
    uid: string,
    name: string,
  ): Promise<void> {
    const count = await (this.prisma[model] as any).count({ where: { ownerUid: uid, name } });
    if (count > 0) throw new BadRequestException('名稱已存在');
  }
}

function requireName(name: string | undefined): string {
  const n = (name ?? '').trim();
  if (!n) throw new BadRequestException('名稱不可為空');
  return n;
}
