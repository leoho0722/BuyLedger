'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { Suspense, useEffect, useState } from 'react';
import { PageHeader } from '@/components/PageHeader';
import { OrderEditForm, type OrderFormInitial } from '@/features/orders/OrderEditForm';

export default function NewOrderPage() {
  return (
    <Suspense fallback={<p className="py-12 text-center text-bl-secondary-label">載入中…</p>}>
      <NewOrderInner />
    </Suspense>
  );
}

function NewOrderInner() {
  const router = useRouter();
  const params = useSearchParams();
  const isMerge = params.get('merge') === '1';
  const [initial, setInitial] = useState<OrderFormInitial | undefined>(undefined);
  const [ready, setReady] = useState(!isMerge);

  // 合併草稿暫存在 sessionStorage；待讀取完成才掛載表單 (initial 只在初次生效)。
  useEffect(() => {
    if (!isMerge) return;
    const raw = sessionStorage.getItem('bl-merge-draft');
    if (raw) {
      try {
        setInitial(JSON.parse(raw) as OrderFormInitial);
      } catch {
        /* ignore */
      }
    }
    setReady(true);
  }, [isMerge]);

  if (!ready) return <p className="py-12 text-center text-bl-secondary-label">載入中…</p>;

  return (
    <div>
      <PageHeader title={isMerge ? '合併訂單' : '新增訂單'} />
      <OrderEditForm
        mode="create"
        initial={initial}
        onSaved={(o) => {
          sessionStorage.removeItem('bl-merge-draft');
          router.push(`/orders/${o.id}`);
        }}
        onCancel={() => router.back()}
      />
    </div>
  );
}
