// 開發/示範用種子資料。可重複執行 (先清空再寫入)
// 注意：FX 匯率快照刻意不種 (無 API key 時應顯示空狀態，不偽造數字)
import { randomUUID } from 'node:crypto';
import { PrismaClient, Prisma } from '@prisma/client';

const prisma = new PrismaClient();

// dev 種子資料的擁有者 uid (對齊 spec「Seeded development data carries explicit ownership」)；
// 可用 SEED_OWNER_UID 覆寫成實際 Firebase uid 以便用該帳號登入看到種子資料
const SEED_OWNER = process.env.SEED_OWNER_UID ?? 'dev-user';

const base = process.env.BUYLEDGER_FIXED_NOW
  ? new Date(process.env.BUYLEDGER_FIXED_NOW)
  : new Date();

// n 天前 (負值為未來)
function daysAgo(n: number): Date {
  return new Date(base.getTime() - n * 86_400_000);
}

function deriveInitials(name: string): string {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
  const first = name.trim()[0] ?? '?';
  return /[A-Za-z]/.test(first) ? name.trim().slice(0, 2).toUpperCase() : first;
}

interface Item {
  name: string;
  quantity: number;
  unitPrice: string;
}

interface OrderSeed {
  id: string;
  customerName: string;
  customerTier?: 'new' | 'regular' | 'vip';
  status: string;
  currency: string;
  date: Date;
  items: Item[];
  itemCost: string;
  chargedAmount: string;
  cardFeeRate?: string;
  platformFeeRate?: string;
  paymentFeeRate?: string;
  domesticShipping?: string;
  internationalShipping?: string;
  foreignDomesticShipping?: string;
  cardlessDeductionAmount?: string;
  cardlessSupplementAmount?: string;
  orderSource: string;
  categories: string[];
  paymentMethod: string;
  notes?: string;
  verificationStatus?: string;
  campaignNames?: string[];
  paymentReceiptStatus?: 'pending' | 'received';
  isCashOnDelivery?: boolean;
  mergedSourceIDs?: string[];
}

function toRow(o: OrderSeed): Prisma.OrderCreateManyInput {
  return {
    id: o.id,
    ownerUid: SEED_OWNER,
    customerName: o.customerName,
    customerInitials: deriveInitials(o.customerName),
    customerTier: o.customerTier ?? 'regular',
    status: o.status,
    currency: o.currency,
    date: o.date,
    items: o.items.map((it) => ({ id: randomUUID(), ...it })) as unknown as Prisma.InputJsonValue,
    itemCost: o.itemCost,
    domesticShipping: o.domesticShipping ?? '0',
    internationalShipping: o.internationalShipping ?? '0',
    foreignDomesticShipping: o.foreignDomesticShipping ?? '0',
    cardFeeRate: o.cardFeeRate ?? '0.02',
    platformFeeRate: o.platformFeeRate ?? '0.03',
    paymentFeeRate: o.paymentFeeRate ?? '0',
    chargedAmount: o.chargedAmount,
    cardlessDeductionAmount: o.cardlessDeductionAmount ?? '0',
    cardlessSupplementAmount: o.cardlessSupplementAmount ?? '0',
    orderSource: o.orderSource,
    categories: o.categories,
    paymentMethod: o.paymentMethod,
    notes: o.notes ?? '',
    verificationStatus: o.verificationStatus ?? '',
    campaignNames: o.campaignNames ?? [],
    paymentReceiptStatus: o.paymentReceiptStatus ?? 'pending',
    isCashOnDelivery: o.isCashOnDelivery ?? false,
    photos: [],
    mergedSourceIDs: o.mergedSourceIDs ?? [],
  };
}

const orders: OrderSeed[] = [
  {
    id: 'BL-0001', customerName: '王小明', customerTier: 'vip', status: 'delivered', currency: 'JPY',
    date: daysAgo(3), items: [{ name: '資生堂洗面乳', quantity: 2, unitPrice: '1800' }, { name: 'SK-II 神仙水', quantity: 1, unitPrice: '12000' }],
    itemCost: '4200', chargedAmount: '6800', orderSource: '蝦皮', categories: ['美妝'],
    paymentMethod: '信用卡', campaignNames: ['六月日本團'], paymentReceiptStatus: 'received',
  },
  {
    id: 'BL-0002', customerName: '林美華', customerTier: 'regular', status: 'arrived', currency: 'JPY',
    date: daysAgo(5), items: [{ name: 'Uniqlo 羽絨外套', quantity: 1, unitPrice: '5900' }],
    itemCost: '1600', chargedAmount: '2400', orderSource: 'IG', categories: ['服飾'],
    paymentMethod: '信用卡', campaignNames: ['六月日本團'], paymentReceiptStatus: 'received',
  },
  {
    id: 'BL-0003', customerName: '陳大文', customerTier: 'new', status: 'shipping', currency: 'KRW',
    date: daysAgo(2), items: [{ name: 'innisfree 綠茶精華', quantity: 3, unitPrice: '32000' }],
    itemCost: '2100', chargedAmount: '3200', orderSource: 'LINE', categories: ['美妝'],
    paymentMethod: '銀行轉帳', verificationStatus: '待對帳', campaignNames: ['五月韓國團'], paymentReceiptStatus: 'pending',
  },
  {
    id: 'BL-0004', customerName: '張雅婷', customerTier: 'vip', status: 'delivered', currency: 'KRW',
    date: daysAgo(8), items: [{ name: '韓妞氣墊粉餅', quantity: 4, unitPrice: '28000' }],
    itemCost: '3000', chargedAmount: '4800', orderSource: '代購社團', categories: ['美妝'],
    paymentMethod: '信用卡', campaignNames: ['五月韓國團'], paymentReceiptStatus: 'received',
  },
  {
    id: 'BL-0005', customerName: '王小明', customerTier: 'vip', status: 'purchased', currency: 'JPY',
    date: daysAgo(1), items: [{ name: 'Nintendo Switch 2', quantity: 1, unitPrice: '49980' }],
    itemCost: '11000', chargedAmount: '14500', orderSource: '官網', categories: ['3C'],
    paymentMethod: '無卡分期', cardlessDeductionAmount: '500', cardlessSupplementAmount: '0',
    paymentReceiptStatus: 'pending', campaignNames: ['六月日本團'],
  },
  {
    id: 'BL-0006', customerName: '李宗翰', customerTier: 'regular', status: 'confirmed', currency: 'USD',
    date: daysAgo(4), items: [{ name: 'Kindle Paperwhite', quantity: 1, unitPrice: '159' }],
    itemCost: '4200', chargedAmount: '5600', orderSource: '官網', categories: ['3C'],
    paymentMethod: '貨到付款', isCashOnDelivery: true, domesticShipping: '60', internationalShipping: '350',
    paymentReceiptStatus: 'pending',
  },
  {
    id: 'BL-0007', customerName: '林美華', customerTier: 'regular', status: 'delivered', currency: 'JPY',
    date: daysAgo(12), items: [{ name: '白色戀人餅乾', quantity: 5, unitPrice: '1200' }],
    itemCost: '1500', chargedAmount: '2600', orderSource: '蝦皮', categories: ['食品'],
    paymentMethod: '信用卡', paymentReceiptStatus: 'received',
  },
  {
    id: 'BL-0008', customerName: '黃靜怡', customerTier: 'new', status: 'quoting', currency: 'JPY',
    date: daysAgo(0), items: [{ name: 'CASETiFY 手機殼', quantity: 2, unitPrice: '6800' }],
    itemCost: '2400', chargedAmount: '3600', orderSource: 'IG', categories: ['生活雜貨'],
    paymentMethod: '信用卡', paymentReceiptStatus: 'pending',
  },
  {
    id: 'BL-0009', customerName: '吳建德', customerTier: 'regular', status: 'cancelled', currency: 'KRW',
    date: daysAgo(15), items: [{ name: '韓國泡麵組', quantity: 10, unitPrice: '1500' }],
    itemCost: '900', chargedAmount: '1500', orderSource: 'LINE', categories: ['食品'],
    paymentMethod: '信用卡', paymentReceiptStatus: 'pending',
  },
  {
    id: 'BL-0010', customerName: '張雅婷', customerTier: 'vip', status: 'partiallyArrived', currency: 'JPY',
    date: daysAgo(6), items: [{ name: 'MUJI 收納盒', quantity: 6, unitPrice: '590' }, { name: 'MUJI 香氛機', quantity: 1, unitPrice: '7900' }],
    itemCost: '2800', chargedAmount: '4200', orderSource: '官網', categories: ['生活雜貨'],
    paymentMethod: '街口支付', paymentReceiptStatus: 'received',
  },
  {
    id: 'BL-0011', customerName: '陳大文', customerTier: 'new', status: 'arrived', currency: 'USD',
    date: daysAgo(9), items: [{ name: 'Stanley 保溫杯', quantity: 2, unitPrice: '45' }],
    itemCost: '1800', chargedAmount: '3000', orderSource: '代購社團', categories: ['生活雜貨'],
    paymentMethod: '信用卡', campaignNames: ['六月零食團'], paymentReceiptStatus: 'pending',
  },
  {
    id: 'BL-0012', customerName: '李宗翰', customerTier: 'regular', status: 'delivered', currency: 'JPY',
    date: daysAgo(20), items: [{ name: '東京香蕉蛋糕', quantity: 8, unitPrice: '1080' }],
    itemCost: '2200', chargedAmount: '3800', orderSource: '蝦皮', categories: ['食品'],
    paymentMethod: '信用卡', campaignNames: ['六月零食團'], paymentReceiptStatus: 'received',
  },
  // 合併示範：兩筆來源訂單 (已合併) + 一筆合併結果
  {
    id: 'BL-0013', customerName: '黃靜怡', customerTier: 'new', status: 'merged', currency: 'JPY',
    date: daysAgo(7), items: [{ name: 'Disney 玩偶', quantity: 1, unitPrice: '3200' }],
    itemCost: '1000', chargedAmount: '1800', orderSource: 'IG', categories: ['生活雜貨'],
    paymentMethod: '信用卡', paymentReceiptStatus: 'received',
  },
  {
    id: 'BL-0014', customerName: '黃靜怡', customerTier: 'new', status: 'merged', currency: 'JPY',
    date: daysAgo(7), items: [{ name: '吉卜力周邊', quantity: 2, unitPrice: '2400' }],
    itemCost: '1400', chargedAmount: '2200', orderSource: 'IG', categories: ['美妝'],
    paymentMethod: '信用卡', paymentReceiptStatus: 'received',
  },
  {
    id: 'BL-0015', customerName: '黃靜怡', customerTier: 'new', status: 'shipping', currency: 'JPY',
    date: daysAgo(6), items: [{ name: 'Disney 玩偶', quantity: 1, unitPrice: '3200' }, { name: '吉卜力周邊', quantity: 2, unitPrice: '2400' }],
    itemCost: '2400', chargedAmount: '4000', orderSource: 'IG', categories: ['生活雜貨', '美妝'],
    paymentMethod: '信用卡', paymentReceiptStatus: 'received', mergedSourceIDs: ['BL-0013', 'BL-0014'],
  },
];

const campaigns = [
  { id: randomUUID(), name: '六月日本團', openDate: daysAgo(20), closeDate: daysAgo(-10), status: 'ongoing', settledDate: null, notes: '主打美妝與電玩' },
  { id: randomUUID(), name: '五月韓國團', openDate: daysAgo(50), closeDate: daysAgo(20), status: 'closed', settledDate: daysAgo(15), notes: '已結團' },
  { id: randomUUID(), name: '三月美妝團', openDate: daysAgo(95), closeDate: null, status: 'ongoing', settledDate: null, notes: '' },
  { id: randomUUID(), name: '六月零食團', openDate: daysAgo(10), closeDate: daysAgo(-20), status: 'ongoing', settledDate: null, notes: '日韓零食' },
];

async function main(): Promise<void> {
  // 已有資料則略過 (避免容器每次啟動覆蓋使用者資料)；SEED_FORCE=true 可強制重置
  if (process.env.SEED_FORCE !== 'true') {
    const existing = await prisma.order.count();
    if (existing > 0) {
      // eslint-disable-next-line no-console
      console.log('資料庫已有訂單，略過種子。');
      return;
    }
  }

  // 清空後重新寫入
  await prisma.order.deleteMany();
  await prisma.campaign.deleteMany();
  await prisma.category.deleteMany();
  await prisma.orderSource.deleteMany();
  await prisma.paymentMethod.deleteMany();
  await prisma.verificationStatus.deleteMany();
  await prisma.settings.deleteMany();
  await prisma.currencyMetadata.deleteMany();

  await prisma.category.createMany({
    data: ['美妝', '3C', '服飾', '食品', '生活雜貨'].map((name) => ({ ownerUid: SEED_OWNER, name })),
  });
  await prisma.orderSource.createMany({
    data: ['官網', '蝦皮', 'IG', 'LINE', '代購社團'].map((name) => ({ ownerUid: SEED_OWNER, name })),
  });
  await prisma.verificationStatus.createMany({
    data: ['待對帳', '對帳成功', '對帳異常'].map((name) => ({ ownerUid: SEED_OWNER, name })),
  });
  await prisma.paymentMethod.createMany({
    data: [
      { name: '信用卡', isCardless: false, isBankTransfer: false, isCashOnDelivery: false },
      { name: '無卡分期', isCardless: true, isBankTransfer: false, isCashOnDelivery: false },
      { name: '銀行轉帳', isCardless: false, isBankTransfer: true, isCashOnDelivery: false },
      { name: '貨到付款', isCardless: false, isBankTransfer: false, isCashOnDelivery: true },
      { name: '街口支付', isCardless: false, isBankTransfer: false, isCashOnDelivery: false },
    ].map((pm) => ({ ...pm, ownerUid: SEED_OWNER })),
  });

  await prisma.campaign.createMany({
    data: campaigns.map((c) => ({ ...c, ownerUid: SEED_OWNER })),
  });
  await prisma.order.createMany({ data: orders.map(toRow) });
  await prisma.settings.create({ data: { ownerUid: SEED_OWNER } });
  await prisma.currencyMetadata.create({
    data: { id: 'singleton', codes: ['TWD', 'JPY', 'KRW', 'USD', 'CNY', 'EUR', 'GBP', 'HKD', 'THB', 'SGD'], updatedAt: null },
  });

  // eslint-disable-next-line no-console
  console.log(`已種子：${orders.length} 筆訂單、${campaigns.length} 個開團、主檔與設定。`);
}

main()
  .catch((err) => {
    // eslint-disable-next-line no-console
    console.error(err);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
