import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
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
  ) {}

  // MARK: - 商品類別

  async listCategories(): Promise<string[]> {
    const rows = await this.prisma.category.findMany({ orderBy: { name: 'asc' } });
    return rows.map((r) => r.name);
  }

  async addCategory(name: string): Promise<string[]> {
    const n = requireName(name);
    await this.prisma.category.upsert({ where: { name: n }, create: { name: n }, update: {} });
    return this.listCategories();
  }

  async renameCategory(oldName: string, newName: string): Promise<string[]> {
    const n = requireName(newName);
    await this.ensureExists('category', oldName);
    if (n !== oldName) {
      await this.assertFree('category', n);
      await this.orders.cascadeRenameCategory(oldName, n);
      await this.prisma.$transaction([
        this.prisma.category.create({ data: { name: n } }),
        this.prisma.category.delete({ where: { name: oldName } }),
      ]);
    }
    return this.listCategories();
  }

  async removeCategory(name: string): Promise<string[]> {
    await this.prisma.category.deleteMany({ where: { name } });
    return this.listCategories();
  }

  // MARK: - 訂單來源

  async listOrderSources(): Promise<string[]> {
    const rows = await this.prisma.orderSource.findMany({ orderBy: { name: 'asc' } });
    return rows.map((r) => r.name);
  }

  async addOrderSource(name: string): Promise<string[]> {
    const n = requireName(name);
    await this.prisma.orderSource.upsert({ where: { name: n }, create: { name: n }, update: {} });
    return this.listOrderSources();
  }

  async renameOrderSource(oldName: string, newName: string): Promise<string[]> {
    const n = requireName(newName);
    await this.ensureExists('orderSource', oldName);
    if (n !== oldName) {
      await this.assertFree('orderSource', n);
      await this.orders.cascadeRenameScalar('orderSource', oldName, n);
      await this.prisma.$transaction([
        this.prisma.orderSource.create({ data: { name: n } }),
        this.prisma.orderSource.delete({ where: { name: oldName } }),
      ]);
    }
    return this.listOrderSources();
  }

  async removeOrderSource(name: string): Promise<string[]> {
    await this.prisma.orderSource.deleteMany({ where: { name } });
    return this.listOrderSources();
  }

  // MARK: - 對帳狀態

  async listVerificationStatuses(): Promise<string[]> {
    const rows = await this.prisma.verificationStatus.findMany({ orderBy: { name: 'asc' } });
    return rows.map((r) => r.name);
  }

  async addVerificationStatus(name: string): Promise<string[]> {
    const n = requireName(name);
    await this.prisma.verificationStatus.upsert({ where: { name: n }, create: { name: n }, update: {} });
    return this.listVerificationStatuses();
  }

  async renameVerificationStatus(oldName: string, newName: string): Promise<string[]> {
    const n = requireName(newName);
    await this.ensureExists('verificationStatus', oldName);
    if (n !== oldName) {
      await this.assertFree('verificationStatus', n);
      await this.orders.cascadeRenameScalar('verificationStatus', oldName, n);
      await this.prisma.$transaction([
        this.prisma.verificationStatus.create({ data: { name: n } }),
        this.prisma.verificationStatus.delete({ where: { name: oldName } }),
      ]);
    }
    return this.listVerificationStatuses();
  }

  async removeVerificationStatus(name: string): Promise<string[]> {
    await this.prisma.verificationStatus.deleteMany({ where: { name } });
    return this.listVerificationStatuses();
  }

  // MARK: - 付款方式 (帶旗標)

  async listPaymentMethods(): Promise<PaymentMethodDTO[]> {
    const rows = await this.prisma.paymentMethod.findMany({ orderBy: { name: 'asc' } });
    return rows.map((r) => ({
      name: r.name,
      isCardless: r.isCardless,
      isBankTransfer: r.isBankTransfer,
      isCashOnDelivery: r.isCashOnDelivery,
    }));
  }

  async addPaymentMethod(input: PaymentMethodInput): Promise<PaymentMethodDTO[]> {
    const n = requireName(input.name);
    await this.prisma.paymentMethod.upsert({
      where: { name: n },
      create: {
        name: n,
        isCardless: input.isCardless ?? false,
        isBankTransfer: input.isBankTransfer ?? false,
        isCashOnDelivery: input.isCashOnDelivery ?? false,
      },
      update: {
        isCardless: input.isCardless ?? false,
        isBankTransfer: input.isBankTransfer ?? false,
        isCashOnDelivery: input.isCashOnDelivery ?? false,
      },
    });
    return this.listPaymentMethods();
  }

  // 編輯付款方式：改名 (cascade) 並把三旗標設成「使用者選擇的確切值」(含清除既有旗標)。
  async updatePaymentMethod(
    oldName: string,
    input: PaymentMethodInput,
  ): Promise<PaymentMethodDTO[]> {
    const existing = await this.prisma.paymentMethod.findUnique({ where: { name: oldName } });
    if (!existing) throw new NotFoundException(`找不到付款方式 ${oldName}`);
    const n = requireName(input.name ?? oldName);

    const flags = {
      isCardless: input.isCardless ?? false,
      isBankTransfer: input.isBankTransfer ?? false,
      isCashOnDelivery: input.isCashOnDelivery ?? false,
    };

    if (n !== oldName) {
      const clash = await this.prisma.paymentMethod.findUnique({ where: { name: n } });
      if (clash) throw new BadRequestException('名稱已存在');
      await this.orders.cascadeRenameScalar('paymentMethod', oldName, n);
      await this.prisma.$transaction([
        this.prisma.paymentMethod.create({ data: { name: n, ...flags } }),
        this.prisma.paymentMethod.delete({ where: { name: oldName } }),
      ]);
    } else {
      await this.prisma.paymentMethod.update({ where: { name: oldName }, data: flags });
    }
    return this.listPaymentMethods();
  }

  async removePaymentMethod(name: string): Promise<PaymentMethodDTO[]> {
    await this.prisma.paymentMethod.deleteMany({ where: { name } });
    return this.listPaymentMethods();
  }

  // MARK: - 私有

  private async ensureExists(
    model: 'category' | 'orderSource' | 'verificationStatus',
    name: string,
  ): Promise<void> {
    const count = await (this.prisma[model] as any).count({ where: { name } });
    if (count === 0) throw new NotFoundException(`找不到 ${name}`);
  }

  private async assertFree(
    model: 'category' | 'orderSource' | 'verificationStatus',
    name: string,
  ): Promise<void> {
    const count = await (this.prisma[model] as any).count({ where: { name } });
    if (count > 0) throw new BadRequestException('名稱已存在');
  }
}

function requireName(name: string | undefined): string {
  const n = (name ?? '').trim();
  if (!n) throw new BadRequestException('名稱不可為空');
  return n;
}
