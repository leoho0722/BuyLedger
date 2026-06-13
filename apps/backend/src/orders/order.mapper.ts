import type { Order as OrderRow } from '@prisma/client';
import type { LedgerOrder, LedgerOrderItem } from '../data-model';
import { computeOrderSummary, OrderSummary } from '../domain/order-summary';

// 對外的訂單 DTO：生成型別 + 後端算好的財務摘要。
export type OrderDTO = LedgerOrder & { summary: OrderSummary };

// Prisma 列轉領域型別 (decimal → 字串、date → ISO)。
export function rowToDomain(row: OrderRow): LedgerOrder {
  return {
    id: row.id,
    customer: {
      name: row.customerName,
      initials: row.customerInitials,
      tier: row.customerTier as LedgerOrder['customer']['tier'],
    },
    status: row.status as LedgerOrder['status'],
    currency: row.currency,
    date: row.date.toISOString(),
    items: (row.items as unknown as LedgerOrderItem[]) ?? [],
    itemCost: row.itemCost.toString(),
    domesticShipping: row.domesticShipping.toString(),
    internationalShipping: row.internationalShipping.toString(),
    foreignDomesticShipping: row.foreignDomesticShipping.toString(),
    cardFeeRate: row.cardFeeRate.toString(),
    platformFeeRate: row.platformFeeRate.toString(),
    paymentFeeRate: row.paymentFeeRate.toString(),
    chargedAmount: row.chargedAmount.toString(),
    cardlessDeductionAmount: row.cardlessDeductionAmount.toString(),
    cardlessSupplementAmount: row.cardlessSupplementAmount.toString(),
    orderSource: row.orderSource,
    categories: row.categories,
    paymentMethod: row.paymentMethod,
    notes: row.notes,
    verificationStatus: row.verificationStatus,
    campaignNames: row.campaignNames,
    paymentReceiptStatus: row.paymentReceiptStatus as LedgerOrder['paymentReceiptStatus'],
    isCashOnDelivery: row.isCashOnDelivery,
    photos: row.photos,
    mergedSourceIDs: row.mergedSourceIDs,
  };
}

// 領域型別 + 摘要組成 DTO。
export function domainToDto(order: LedgerOrder): OrderDTO {
  return { ...order, summary: computeOrderSummary(order) };
}

export function rowToDto(row: OrderRow): OrderDTO {
  return domainToDto(rowToDomain(row));
}
