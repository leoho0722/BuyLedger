// firebase-admin (ESM jose) 經 FirestoreMirrorService 間接載入，需 mock
jest.mock('firebase-admin/app', () => ({
  initializeApp: jest.fn(),
  getApps: jest.fn(() => []),
  cert: jest.fn(),
}));
jest.mock('firebase-admin/auth', () => ({ getAuth: jest.fn() }));
jest.mock('firebase-admin/firestore', () => ({ getFirestore: jest.fn() }));
jest.mock('firebase-admin/storage', () => ({ getStorage: jest.fn() }));

import * as fs from 'node:fs';
import * as path from 'node:path';

import type { LedgerOrder } from '../data-model';
import { orderDomainToFlat } from './orders.service';

// 唯一分類來源：後端合併圖須與其同步防分類漂移
const categoriesPath = path.join(
  __dirname,
  '../../../../shared/sync-conformance/field-categories.json',
);
const fieldCategories = JSON.parse(fs.readFileSync(categoriesPath, 'utf8'));
const orderFields: Record<string, { category: string }> =
  fieldCategories.entities.Order.fields;

// 巢狀 customer 攤平後的 flat 欄位名對應分類來源欄位名 (其餘同名)
const FLAT_TO_CATEGORY_FIELD: Record<string, string> = {
  customerName: 'customerName',
  customerTier: 'customerTier',
};

function sampleOrder(): LedgerOrder {
  return {
    id: 'ORD1',
    customer: { name: '王', initials: 'W', tier: 'new' },
    status: 'quoting',
    currency: 'TWD',
    date: '2024-01-01T00:00:00.000Z',
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
  };
}

// 合併圖須等同分類來源 C+D 類，排除 A 類唯讀與 B 類衍生
describe('Order field-categories conformance (task 2.11)', () => {
  const flatKeys = Object.keys(orderDomainToFlat(sampleOrder()));

  // 可合併欄位 = C 類 ∪ D 類 (D 類加特殊規則仍帶 clock)
  const mergeableCategoryFields = Object.entries(orderFields)
    .filter(([, def]) => def.category === 'C' || def.category === 'D')
    .map(([name]) => name)
    .sort();

  function flatKeyToCategoryField(key: string): string {
    return FLAT_TO_CATEGORY_FIELD[key] ?? key;
  }

  it('merge map covers exactly the C-class and D-class mergeable fields', () => {
    const mappedFlatKeys = flatKeys.map(flatKeyToCategoryField).sort();
    expect(mappedFlatKeys).toEqual(mergeableCategoryFields);
  });

  it('excludes A-class read-only fields from the merge map', () => {
    const aFields = Object.entries(orderFields)
      .filter(([, def]) => def.category === 'A')
      .map(([name]) => name);
    for (const f of aFields) {
      expect(flatKeys).not.toContain(f);
    }
    // 防分類來源被改空：確認 A 類仍含 id / mergedSourceIDs
    expect(aFields).toEqual(expect.arrayContaining(['id', 'mergedSourceIDs']));
  });

  it('excludes B-class derived fields from the merge map', () => {
    const bFields = Object.entries(orderFields)
      .filter(([, def]) => def.category === 'B')
      .map(([name]) => name);
    for (const f of bFields) {
      expect(flatKeys).not.toContain(f);
    }
    // 防分類來源被改空：確認 B 類衍生欄位仍在來源內
    expect(bFields).toContain('customerInitials');
    expect(bFields).toContain('isCashOnDelivery');
  });
});
