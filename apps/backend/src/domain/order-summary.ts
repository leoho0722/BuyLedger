import { D } from './decimal';
import type { LedgerOrder } from '../data-model';

// 訂單財務摘要 (對齊 iOS OrderSummary)；金額一律以字串輸出 (decimal-as-string 契約)。
export interface OrderSummary {
  readonly revenue: string;
  readonly cardFee: string;
  readonly platformFee: string;
  readonly paymentFee: string;
  readonly fees: string;
  readonly totalCost: string;
  readonly codShippingCost: string;
  readonly profit: string;
  readonly margin: string;
}

// 計算所需的訂單財務欄位 (LedgerOrder 子集)。
export type OrderFinancials = Pick<
  LedgerOrder,
  | 'chargedAmount'
  | 'cardFeeRate'
  | 'platformFeeRate'
  | 'paymentFeeRate'
  | 'cardlessSupplementAmount'
  | 'cardlessDeductionAmount'
  | 'itemCost'
  | 'domesticShipping'
  | 'internationalShipping'
  | 'foreignDomesticShipping'
  | 'isCashOnDelivery'
>;

/// 依訂單財務欄位計算摘要。公式逐項對齊 iOS：
/// - 手續費以 chargedAmount 為基準；platformFee 無條件進位到整數。
/// - revenue = chargedAmount + 無卡補款 − 無卡折抵。
/// - 貨到付款時三種運費計入成本，否則為 0。
/// - margin = profit / revenue，revenue 為 0 時為 0。
export function computeOrderSummary(o: OrderFinancials): OrderSummary {
  const charged = D(o.chargedAmount);
  const cardFee = charged.times(o.cardFeeRate);
  // platformFee 無條件進位到整數 (對齊 NSDecimalRound .up；費率非負故 ceil 等價)。
  const platformFee = charged.times(o.platformFeeRate).ceil();
  const paymentFee = charged.times(o.paymentFeeRate);
  const fees = cardFee.plus(platformFee).plus(paymentFee);

  const revenue = charged
    .plus(o.cardlessSupplementAmount)
    .minus(o.cardlessDeductionAmount);

  const codShippingCost = o.isCashOnDelivery
    ? D(o.domesticShipping)
        .plus(o.internationalShipping)
        .plus(o.foreignDomesticShipping)
    : D(0);

  const totalCost = D(o.itemCost).plus(fees).plus(codShippingCost);
  const profit = revenue.minus(totalCost);
  const margin = revenue.isZero() ? D(0) : profit.div(revenue);

  return {
    revenue: revenue.toString(),
    cardFee: cardFee.toString(),
    platformFee: platformFee.toString(),
    paymentFee: paymentFee.toString(),
    fees: fees.toString(),
    totalCost: totalCost.toString(),
    codShippingCost: codShippingCost.toString(),
    profit: profit.toString(),
    margin: margin.toString(),
  };
}
