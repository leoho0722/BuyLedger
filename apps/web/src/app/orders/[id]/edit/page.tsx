'use client';

import { useParams, useRouter } from 'next/navigation';
import { PageHeader } from '@/components/PageHeader';
import { OrderEditForm, type OrderFormInitial } from '@/features/orders/OrderEditForm';
import { useOrder } from '@/lib/queries';

export default function EditOrderPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const { data: order, isLoading } = useOrder(id);

  if (isLoading || !order) {
    return <p className="py-12 text-center text-bl-secondary-label">載入中…</p>;
  }

  const initial: OrderFormInitial = {
    customer: { name: order.customer.name, tier: order.customer.tier },
    status: order.status,
    currency: order.currency,
    date: order.date,
    items: order.items.map((it) => ({
      id: it.id,
      name: it.name,
      quantity: it.quantity,
      unitPrice: it.unitPrice,
    })),
    itemCost: order.itemCost,
    domesticShipping: order.domesticShipping,
    internationalShipping: order.internationalShipping,
    foreignDomesticShipping: order.foreignDomesticShipping,
    cardFeeRate: order.cardFeeRate,
    platformFeeRate: order.platformFeeRate,
    paymentFeeRate: order.paymentFeeRate,
    chargedAmount: order.chargedAmount,
    cardlessDeductionAmount: order.cardlessDeductionAmount,
    cardlessSupplementAmount: order.cardlessSupplementAmount,
    orderSource: order.orderSource,
    categories: order.categories,
    paymentMethod: order.paymentMethod,
    notes: order.notes,
    verificationStatus: order.verificationStatus,
    campaignNames: order.campaignNames,
    paymentReceiptStatus: order.paymentReceiptStatus,
    photos: order.photos,
    mergedSourceIDs: order.mergedSourceIDs,
  };

  return (
    <div>
      <PageHeader title="編輯訂單" />
      <OrderEditForm
        mode="edit"
        orderId={id}
        initial={initial}
        onSaved={() => router.push(`/orders/${id}`)}
        onCancel={() => router.back()}
      />
    </div>
  );
}
