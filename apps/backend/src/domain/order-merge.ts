import { D, Decimal } from './decimal';
import type { LedgerOrder, LedgerOrderItem } from '../data-model';

// 合併草稿：對齊 iOS OrderMerge.Draft，金額以字串輸出。不含訂單 id (儲存時才產生)。
export interface MergeDraft {
  customer: LedgerOrder['customer'];
  orderSource: string;
  status: LedgerOrder['status'];
  currency: string;
  date: string;
  categories: string[];
  campaignNames: string[];
  paymentMethod: string;
  verificationStatus: string;
  isCashOnDelivery: boolean;
  paymentReceiptStatus: LedgerOrder['paymentReceiptStatus'];
  chargedAmount: string;
  cardlessDeductionAmount: string;
  cardlessSupplementAmount: string;
  itemCost: string;
  foreignDomesticShipping: string;
  internationalShipping: string;
  domesticShipping: string;
  cardFeeRate: string;
  platformFeeRate: string;
  paymentFeeRate: string;
  items: LedgerOrderItem[];
  notes: string;
  photos: string[];
  mergeSourceIDs: string[];
}

const NOTES_SEPARATOR = '----------';

/// 依合併規則整合兩筆訂單為草稿 (對齊 iOS OrderMerge.makeDraft)。
/// isCardless 由 caller 從付款方式主檔旗標建構。照片僅串接、不截斷。
export function makeMergeDraft(
  primary: LedgerOrder,
  secondary: LedgerOrder,
  now: Date,
  isCardless: (name: string) => boolean,
): MergeDraft {
  const source = paymentMethodSource(primary, secondary, isCardless);

  return {
    customer: primary.customer,
    orderSource: primary.orderSource,
    status: primary.status,
    currency: primary.currency,
    date: now.toISOString(),
    categories: orderedUnion(primary.categories, secondary.categories),
    campaignNames: orderedUnion(primary.campaignNames, secondary.campaignNames),
    paymentMethod: source.paymentMethod,
    verificationStatus: source.verificationStatus,
    isCashOnDelivery: source.isCashOnDelivery,
    paymentReceiptStatus: primary.paymentReceiptStatus,
    chargedAmount: sum(primary.chargedAmount, secondary.chargedAmount),
    cardlessDeductionAmount: sum(primary.cardlessDeductionAmount, secondary.cardlessDeductionAmount),
    cardlessSupplementAmount: sum(primary.cardlessSupplementAmount, secondary.cardlessSupplementAmount),
    itemCost: sum(primary.itemCost, secondary.itemCost),
    foreignDomesticShipping: sum(primary.foreignDomesticShipping, secondary.foreignDomesticShipping),
    internationalShipping: sum(primary.internationalShipping, secondary.internationalShipping),
    domesticShipping: sum(primary.domesticShipping, secondary.domesticShipping),
    cardFeeRate: weightedRate(primary.cardFeeRate, secondary.cardFeeRate, primary, secondary),
    platformFeeRate: weightedRate(primary.platformFeeRate, secondary.platformFeeRate, primary, secondary),
    paymentFeeRate: weightedRate(primary.paymentFeeRate, secondary.paymentFeeRate, primary, secondary),
    items: [...primary.items, ...secondary.items],
    notes: mergedNotes(primary.notes, secondary.notes),
    photos: [...primary.photos, ...secondary.photos],
    mergeSourceIDs: [primary.id, secondary.id],
  };
}

// 保序聯集：主在前、去重。
function orderedUnion(primary: string[], secondary: string[]): string[] {
  const seen = new Set<string>();
  return [...primary, ...secondary].filter((v) => {
    if (seen.has(v)) return false;
    seen.add(v);
    return true;
  });
}

function sum(a: string, b: string): string {
  return D(a).plus(b).toString();
}

// 以兩筆實付為權重的加權平均比例；分母為 0 沿用主訂單比例，clamp 至 [0, 1]。
function weightedRate(
  primaryRate: string,
  secondaryRate: string,
  primary: LedgerOrder,
  secondary: LedgerOrder,
): string {
  const totalCharged = D(primary.chargedAmount).plus(secondary.chargedAmount);
  if (totalCharged.lte(0)) {
    return D(primaryRate).toString();
  }
  const weighted = D(primaryRate)
    .times(primary.chargedAmount)
    .plus(D(secondaryRate).times(secondary.chargedAmount))
    .div(totalCharged);
  return Decimal.max(0, Decimal.min(1, weighted)).toString();
}

// 兩筆皆非空 (trim 後) 以 dash line 分隔串接；任一邊空取非空者；皆空回空字串。
function mergedNotes(primaryNotes: string, secondaryNotes: string): string {
  const p = primaryNotes.trim();
  const s = secondaryNotes.trim();
  if (p && s) return `${p}\n${NOTES_SEPARATOR}\n${s}`;
  if (p) return p;
  if (s) return s;
  return '';
}

// 付款方式來源：相同取主；不同且恰副屬無卡而主非無卡取副；其餘取主。三欄位同源。
function paymentMethodSource(
  primary: LedgerOrder,
  secondary: LedgerOrder,
  isCardless: (name: string) => boolean,
): { paymentMethod: string; verificationStatus: string; isCashOnDelivery: boolean } {
  let src: LedgerOrder;
  if (primary.paymentMethod === secondary.paymentMethod) {
    src = primary;
  } else if (isCardless(secondary.paymentMethod) && !isCardless(primary.paymentMethod)) {
    src = secondary;
  } else {
    src = primary;
  }
  return {
    paymentMethod: src.paymentMethod,
    verificationStatus: src.verificationStatus,
    isCashOnDelivery: src.isCashOnDelivery,
  };
}
