// 把 OrderInputBody 攤平成後端欄位級合併用的 flat 欄位、與原值 diff 出「真正變更的欄位」，
// 並為每個變更欄位附上一個新 HLC (對齊 cross-device-sync「iOS local-first write then push」的
// web 對應：只送變更欄位 + 時鐘，讓兩裝置改不同欄位時皆存活)。欄位名對齊後端
// orderDomainToFlat：customerName/customerTier 攤平；不送衍生的 isCashOnDelivery 與
// 建立後唯讀的 mergedSourceIDs/customerInitials

import type { OrderInputBody } from '../api';
import type { OrderDTO } from '../types';
import { nextClock } from './hlc';

// 變更欄位集：以後端 flat 欄位名為 key、新值為 value (僅含實際變更的欄位)
export type ChangedFields = Record<string, unknown>;

// 攤平成後端可合併的 flat 欄位 (與 backend orderDomainToFlat 對齊)
function orderInputToFlat(b: OrderInputBody): Record<string, unknown> {
  return {
    customerName: b.customer?.name,
    customerTier: b.customer?.tier,
    status: b.status,
    currency: b.currency,
    date: b.date,
    items: b.items,
    itemCost: b.itemCost,
    domesticShipping: b.domesticShipping,
    internationalShipping: b.internationalShipping,
    foreignDomesticShipping: b.foreignDomesticShipping,
    cardFeeRate: b.cardFeeRate,
    platformFeeRate: b.platformFeeRate,
    paymentFeeRate: b.paymentFeeRate,
    chargedAmount: b.chargedAmount,
    cardlessDeductionAmount: b.cardlessDeductionAmount,
    cardlessSupplementAmount: b.cardlessSupplementAmount,
    orderSource: b.orderSource,
    categories: b.categories,
    paymentMethod: b.paymentMethod,
    notes: b.notes,
    verificationStatus: b.verificationStatus,
    campaignNames: b.campaignNames,
    paymentReceiptStatus: b.paymentReceiptStatus,
    photos: b.photos,
  };
}

// 與原值逐欄比較，回傳實際變更的欄位 (陣列/物件以 JSON 結構比較)
export function diffOrderFields(
  next: OrderInputBody,
  prev: OrderInputBody | null | undefined,
): ChangedFields {
  const nf = orderInputToFlat(next);
  const pf = prev ? orderInputToFlat(prev) : {};
  const changed: ChangedFields = {};
  for (const key of Object.keys(nf)) {
    const a = nf[key];
    if (a === undefined) continue;
    const b = (pf as Record<string, unknown>)[key];
    if (JSON.stringify(a) !== JSON.stringify(b)) changed[key] = a;
  }
  return changed;
}

// 把 flat changedFields 套回 OrderDTO 的樂觀副本 (寫入失敗待送時 UI 仍顯示使用者的編輯值)
// 生成型別為唯讀，故以 spread 不可變組裝
export function applyOptimistic(order: OrderDTO, changedFields: ChangedFields): OrderDTO {
  const scalar: Record<string, unknown> = {};
  let customer = order.customer;
  for (const [key, value] of Object.entries(changedFields)) {
    if (key === 'customerName') customer = { ...customer, name: value as string };
    else if (key === 'customerTier') {
      customer = { ...customer, tier: value as OrderDTO['customer']['tier'] };
    } else {
      scalar[key] = value;
    }
  }
  return { ...order, ...scalar, customer } as unknown as OrderDTO;
}

// 為每個變更欄位產生一個新 HLC，組成後端 PATCH body
export function attachClocks(changedFields: ChangedFields): {
  changedFields: ChangedFields;
  fieldClocks: Record<string, string>;
} {
  const fieldClocks: Record<string, string> = {};
  for (const key of Object.keys(changedFields)) {
    fieldClocks[key] = nextClock();
  }
  return { changedFields, fieldClocks };
}
