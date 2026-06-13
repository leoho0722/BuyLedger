'use client';

import {
  ArrowLeft,
  Check,
  GitMerge,
  MoreHorizontal,
  Pencil,
  Trash2,
} from 'lucide-react';
import { useParams, useRouter } from 'next/navigation';
import { useState } from 'react';
import { BLButton } from '@/components/ds/BLButton';
import { BLCard } from '@/components/ds/BLCard';
import { BLDonutChart } from '@/components/ds/BLDonutChart';
import { BLSegmentedControl } from '@/components/ds/BLSegmentedControl';
import { BLStatusPill } from '@/components/ds/BLStatusPill';
import { BLTagPill } from '@/components/ds/BLTagPill';
import { BLAvatar } from '@/components/ds/BLAvatar';
import { OptionPicker } from '@/components/ds/OptionPicker';
import { SectionHeader } from '@/components/ds/SectionHeader';
import { Sheet } from '@/components/ds/Sheet';
import { cn } from '@/lib/cn';
import { api } from '@/lib/api';
import {
  CATEGORY_TINTS,
  CUSTOMER_TIER_TITLE,
  ORDER_STATUS_ORDER,
  ORDER_STATUS_TITLE,
  ORDER_STATUS_TONE,
} from '@/lib/domain/constants';
import { formatFullTimestamp, formatPercent, formatSignedTWD, formatTWD } from '@/lib/format';
import { useOrder, useOrderMutations, useOrders } from '@/lib/queries';
import type { OrderDTO, OrderStatus } from '@/lib/types';
import type { OrderFormInitial } from '@/features/orders/OrderEditForm';
import { MergeCandidateSheet } from '@/features/orders/MergeCandidateSheet';

export default function OrderDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const { data: order, isLoading } = useOrder(id);
  const { data: orders = [] } = useOrders();
  const { setStatus, setReceipt, remove } = useOrderMutations();

  const [statusPicker, setStatusPicker] = useState(false);
  const [moreOpen, setMoreOpen] = useState(false);
  const [mergeOpen, setMergeOpen] = useState(false);
  const [deleteConfirm, setDeleteConfirm] = useState(false);
  const [photoIndex, setPhotoIndex] = useState<number | null>(null);
  const [mergePhotos, setMergePhotos] = useState<{ all: string[]; draft: OrderFormInitial } | null>(null);
  const [keptPhotos, setKeptPhotos] = useState<string[]>([]);

  if (isLoading || !order) {
    return <p className="py-12 text-center text-bl-secondary-label">載入中…</p>;
  }

  const handlePicked = async (candidate: OrderDTO) => {
    setMergeOpen(false);
    const res = await api.orders.mergeDraft(order.id, candidate.id);
    const draft = draftToInitial(res.draft);
    if (res.photosOverLimit) {
      setKeptPhotos(res.draft.photos.slice(0, res.maxPhotoCount));
      setMergePhotos({ all: res.draft.photos, draft });
    } else {
      sessionStorage.setItem('bl-merge-draft', JSON.stringify(draft));
      router.push('/orders/new?merge=1');
    }
  };

  const confirmMergePhotos = () => {
    if (!mergePhotos) return;
    sessionStorage.setItem(
      'bl-merge-draft',
      JSON.stringify({ ...mergePhotos.draft, photos: keptPhotos }),
    );
    setMergePhotos(null);
    router.push('/orders/new?merge=1');
  };

  const s = order.summary;
  const costSegments = [
    { label: '商品成本', value: Number(order.itemCost), color: CATEGORY_TINTS[0] },
    { label: '手續費', value: Number(s.fees), color: CATEGORY_TINTS[1] },
    { label: '國內運費', value: Number(order.domesticShipping), color: CATEGORY_TINTS[3] },
    { label: '國際運費', value: Number(order.internationalShipping), color: CATEGORY_TINTS[2] },
  ].filter((seg) => seg.value > 0);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <button type="button" onClick={() => router.back()} className="flex items-center gap-1 text-bl-accent">
          <ArrowLeft className="h-5 w-5" />
          返回
        </button>
        <button type="button" onClick={() => setMoreOpen(true)} aria-label="更多">
          <MoreHorizontal className="h-6 w-6 text-bl-accent" />
        </button>
      </div>

      {/* 客戶與狀態 */}
      <BLCard className="space-y-3">
        <div className="flex items-center gap-3">
          <BLAvatar name={order.customer.name} initials={order.customer.initials} size={48} />
          <div className="min-w-0 flex-1">
            <p className="truncate text-[17px] font-semibold text-bl-label">{order.customer.name}</p>
            <p className="text-xs text-bl-secondary-label">
              {CUSTOMER_TIER_TITLE[order.customer.tier]} · {order.id}
            </p>
          </div>
          <BLStatusPill label={ORDER_STATUS_TITLE[order.status]} tone={ORDER_STATUS_TONE[order.status]} />
        </div>
        <InfoRow label="訂購時間" value={formatFullTimestamp(order.date)} />
        <InfoRow label="幣別" value={order.currency} />
        <InfoRow label="訂單來源" value={order.orderSource} />
        <InfoRow label="付款方式" value={order.paymentMethod} />
        {order.verificationStatus && <InfoRow label="對帳狀態" value={order.verificationStatus} />}
        {order.categories.length > 0 && (
          <div className="flex flex-wrap gap-1.5">
            {order.categories.map((c) => (
              <BLTagPill key={c} label={c} />
            ))}
          </div>
        )}
        {order.campaignNames.length > 0 && (
          <InfoRow label="歸屬開團" value={order.campaignNames.join('、')} />
        )}
      </BLCard>

      {/* 收款狀態 */}
      <BLCard className="space-y-2">
        <span className="text-xs font-semibold text-bl-secondary-label">收款狀態</span>
        <BLSegmentedControl
          value={order.paymentReceiptStatus}
          onChange={(v) => setReceipt.mutate({ id: order.id, status: v })}
          options={[
            { value: 'pending', label: '待收款' },
            { value: 'received', label: '已收款' },
          ]}
        />
      </BLCard>

      {/* 財務摘要 */}
      <BLCard className="space-y-3">
        <SectionHeader title="財務摘要" />
        <div className="flex items-center gap-4">
          {costSegments.length > 0 && (
            <BLDonutChart segments={costSegments} centerTitle="總成本" centerValue={formatTWD(s.totalCost)} />
          )}
          <div className="flex-1 space-y-2">
            <Metric label="收益" value={formatTWD(s.revenue)} />
            <Metric
              label="獲利"
              value={formatSignedTWD(Number(s.profit))}
              tone={Number(s.profit) >= 0 ? 'green' : 'red'}
            />
            <Metric label="毛利率" value={formatPercent(s.margin)} />
            <Metric label="手續費" value={formatTWD(s.fees)} />
          </div>
        </div>
      </BLCard>

      {/* 商品明細 */}
      <BLCard className="space-y-2">
        <SectionHeader title="商品明細" />
        {order.items.map((it) => (
          <div key={it.id} className="flex items-center justify-between text-[15px]">
            <span className="text-bl-label">
              {it.name || '未命名商品'} <span className="text-bl-secondary-label">×{it.quantity}</span>
            </span>
            <span className="text-bl-secondary-label bl-tabular">
              {formatTWD(Number(it.unitPrice) * it.quantity)} {order.currency}
            </span>
          </div>
        ))}
      </BLCard>

      {/* 照片 */}
      {order.photos.length > 0 && (
        <BLCard className="space-y-2">
          <SectionHeader title="訂單照片" />
          <div className="flex flex-wrap gap-2">
            {order.photos.map((src, i) => (
              <button key={i} type="button" onClick={() => setPhotoIndex(i)} className="h-20 w-20 overflow-hidden rounded-bl-sm">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={src} alt={`照片 ${i + 1}`} className="h-full w-full object-cover" />
              </button>
            ))}
          </div>
        </BLCard>
      )}

      {/* 備註 */}
      {order.notes.trim() && (
        <BLCard className="space-y-2">
          <SectionHeader title="備註" />
          <p className="whitespace-pre-wrap text-[15px] text-bl-label">{order.notes}</p>
        </BLCard>
      )}

      <BLButton variant="secondary" fullWidth onClick={() => setStatusPicker(true)}>
        更新狀態
      </BLButton>

      {/* 狀態挑選 */}
      <OptionPicker
        open={statusPicker}
        onClose={() => setStatusPicker(false)}
        title="更新狀態"
        searchable={false}
        options={ORDER_STATUS_ORDER.filter((st) => st !== 'merged' || order.status === 'merged').map((st) => ({
          value: st,
          label: ORDER_STATUS_TITLE[st],
        }))}
        selected={order.status}
        onSelect={(v) => setStatus.mutate({ id: order.id, status: v as OrderStatus })}
      />

      {/* 更多選單 */}
      <Sheet open={moreOpen} onClose={() => setMoreOpen(false)} title="訂單操作">
        <div className="space-y-2">
          {order.status !== 'merged' && order.status !== 'cancelled' && (
            <MenuButton icon={GitMerge} label="合併訂單" onClick={() => { setMoreOpen(false); setMergeOpen(true); }} />
          )}
          <MenuButton icon={Pencil} label="編輯" onClick={() => { setMoreOpen(false); router.push(`/orders/${order.id}/edit`); }} />
          <MenuButton
            icon={Trash2}
            label="刪除"
            destructive
            onClick={() => { setMoreOpen(false); setDeleteConfirm(true); }}
          />
        </div>
      </Sheet>

      {/* 刪除確認 */}
      <Sheet open={deleteConfirm} onClose={() => setDeleteConfirm(false)} title="刪除訂單">
        <div className="space-y-4 py-2 text-center">
          <p className="text-[15px] text-bl-secondary-label">確定要刪除這筆訂單嗎？此操作無法復原。</p>
          <div className="flex gap-3">
            <BLButton variant="secondary" fullWidth onClick={() => setDeleteConfirm(false)}>
              取消
            </BLButton>
            <BLButton
              variant="destructive"
              fullWidth
              onClick={() => remove.mutate(order.id, { onSuccess: () => router.push('/orders') })}
            >
              刪除
            </BLButton>
          </div>
        </div>
      </Sheet>

      {/* 合併候選 */}
      <MergeCandidateSheet
        open={mergeOpen}
        onClose={() => setMergeOpen(false)}
        primary={order}
        orders={orders}
        onPicked={handlePicked}
      />

      {/* 合併照片挑選 (超過上限) */}
      <Sheet
        open={mergePhotos !== null}
        onClose={() => setMergePhotos(null)}
        title={`選擇保留照片 (${keptPhotos.length}/5)`}
        trailing={
          <button
            type="button"
            disabled={keptPhotos.length === 0}
            onClick={confirmMergePhotos}
            className="text-[17px] font-semibold text-bl-accent disabled:opacity-40"
          >
            完成
          </button>
        }
      >
        <div className="flex flex-wrap gap-2">
          {mergePhotos?.all.map((src, i) => {
            const selected = keptPhotos.includes(src);
            return (
              <button
                key={i}
                type="button"
                onClick={() =>
                  setKeptPhotos((prev) =>
                    prev.includes(src)
                      ? prev.filter((x) => x !== src)
                      : prev.length < 5
                        ? [...prev, src]
                        : prev,
                  )
                }
                className={cn(
                  'relative h-24 w-24 overflow-hidden rounded-bl-sm border-2',
                  selected ? 'border-bl-accent' : 'border-transparent',
                )}
              >
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={src} alt={`照片 ${i + 1}`} className="h-full w-full object-cover" />
                {selected && (
                  <span className="absolute right-1 top-1 rounded-full bg-bl-accent p-0.5 text-white">
                    <Check className="h-3 w-3" />
                  </span>
                )}
              </button>
            );
          })}
        </div>
      </Sheet>

      {/* 照片檢視 */}
      {photoIndex !== null && (
        <PhotoViewer
          photos={order.photos}
          index={photoIndex}
          onIndex={setPhotoIndex}
          onClose={() => setPhotoIndex(null)}
        />
      )}
    </div>
  );
}

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between gap-3 text-[15px]">
      <span className="shrink-0 text-bl-secondary-label">{label}</span>
      <span className="truncate text-right text-bl-label">{value}</span>
    </div>
  );
}

function Metric({ label, value, tone }: { label: string; value: string; tone?: 'green' | 'red' }) {
  return (
    <div className="flex items-center justify-between text-[15px]">
      <span className="text-bl-secondary-label">{label}</span>
      <span
        className={cn(
          'font-semibold bl-tabular',
          tone === 'green' ? 'text-bl-green' : tone === 'red' ? 'text-bl-red' : 'text-bl-label',
        )}
      >
        {value}
      </span>
    </div>
  );
}

function MenuButton({
  icon: Icon,
  label,
  onClick,
  destructive,
}: {
  icon: typeof GitMerge;
  label: string;
  onClick: () => void;
  destructive?: boolean;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        'flex w-full items-center gap-3 rounded-bl-sm px-3 py-3 text-left text-[15px]',
        destructive ? 'text-bl-red' : 'text-bl-label',
      )}
    >
      <Icon className="h-5 w-5" />
      {label}
    </button>
  );
}

function PhotoViewer({
  photos,
  index,
  onIndex,
  onClose,
}: {
  photos: string[];
  index: number;
  onIndex: (i: number) => void;
  onClose: () => void;
}) {
  return (
    <Sheet open onClose={onClose} title={`${index + 1} / ${photos.length}`}>
      <div className="space-y-3">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src={photos[index]} alt="照片" className="mx-auto max-h-[60vh] rounded-bl-md object-contain" />
        <div className="flex justify-between">
          <BLButton variant="plain" onClick={() => onIndex(Math.max(0, index - 1))} disabled={index === 0}>
            上一張
          </BLButton>
          <BLButton
            variant="plain"
            onClick={() => onIndex(Math.min(photos.length - 1, index + 1))}
            disabled={index === photos.length - 1}
          >
            下一張
          </BLButton>
        </div>
      </div>
    </Sheet>
  );
}

// 合併草稿 → 表單初始值。
function draftToInitial(draft: import('@/lib/types').MergeDraftDTO): OrderFormInitial {
  return {
    customer: { name: draft.customer.name, tier: draft.customer.tier },
    status: draft.status,
    currency: draft.currency,
    date: draft.date,
    items: draft.items.map((it) => ({
      id: it.id,
      name: it.name,
      quantity: it.quantity,
      unitPrice: it.unitPrice,
    })),
    itemCost: draft.itemCost,
    domesticShipping: draft.domesticShipping,
    internationalShipping: draft.internationalShipping,
    foreignDomesticShipping: draft.foreignDomesticShipping,
    cardFeeRate: draft.cardFeeRate,
    platformFeeRate: draft.platformFeeRate,
    paymentFeeRate: draft.paymentFeeRate,
    chargedAmount: draft.chargedAmount,
    cardlessDeductionAmount: draft.cardlessDeductionAmount,
    cardlessSupplementAmount: draft.cardlessSupplementAmount,
    orderSource: draft.orderSource,
    categories: draft.categories,
    paymentMethod: draft.paymentMethod,
    notes: draft.notes,
    verificationStatus: draft.verificationStatus,
    campaignNames: draft.campaignNames,
    paymentReceiptStatus: draft.paymentReceiptStatus,
    photos: draft.photos,
    mergedSourceIDs: draft.mergeSourceIDs,
  };
}
