'use client';

import { ArrowLeft, CheckCircle2, ChevronDown, MoreHorizontal } from 'lucide-react';
import { useParams, useRouter } from 'next/navigation';
import { useState } from 'react';
import { BLButton } from '@/components/ds/BLButton';
import { BLCard } from '@/components/ds/BLCard';
import { BLProgressBar } from '@/components/ds/BLProgressBar';
import { BLStatusPill } from '@/components/ds/BLStatusPill';
import { BLToggle } from '@/components/ds/BLToggle';
import { OptionPicker } from '@/components/ds/OptionPicker';
import { SectionHeader } from '@/components/ds/SectionHeader';
import { Sheet } from '@/components/ds/Sheet';
import { cn } from '@/lib/cn';
import { CAMPAIGN_STATUS_TITLE, CAMPAIGN_STATUS_TONE, RECEIPT_STATUS_TITLE } from '@/lib/domain/constants';
import { campaignSummary } from '@/lib/domain/aggregations';
import { formatProgressPercent, formatPercent, formatShortDate, formatTWD } from '@/lib/format';
import {
  useCampaign,
  useCampaignMutations,
  useOrderMutations,
  useOrders,
} from '@/lib/queries';
import type { CampaignStatus } from '@/lib/types';

export default function CampaignDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const { data: campaign, isLoading } = useCampaign(id);
  const { data: orders = [] } = useOrders();
  const { settle, setStatus, remove } = useCampaignMutations();
  const { setReceipt } = useOrderMutations();

  const [moreOpen, setMoreOpen] = useState(false);
  const [statusPicker, setStatusPicker] = useState(false);
  const [deleteConfirm, setDeleteConfirm] = useState(false);
  const [unpaidOnly, setUnpaidOnly] = useState(false);
  const [expanded, setExpanded] = useState<Set<string>>(new Set());

  if (isLoading || !campaign) {
    return <p className="py-12 text-center text-bl-secondary-label">載入中…</p>;
  }

  const summary = campaignSummary(orders, campaign.name);
  const distribution = unpaidOnly
    ? summary.distribution.filter((d) => !d.isFullyReceived)
    : summary.distribution;

  const toggleExpand = (name: string) =>
    setExpanded((prev) => {
      const next = new Set(prev);
      if (next.has(name)) next.delete(name);
      else next.add(name);
      return next;
    });

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

      {/* 開團資訊 */}
      <BLCard className="space-y-2">
        <div className="flex items-center justify-between gap-2">
          <span className="text-[20px] font-bold text-bl-label">{campaign.name}</span>
          <div className="flex items-center gap-1.5">
            {campaign.settledDate && <BLStatusPill label="已結團" tone="neutral" showIndicator={false} />}
            <BLStatusPill label={CAMPAIGN_STATUS_TITLE[campaign.status]} tone={CAMPAIGN_STATUS_TONE[campaign.status]} />
          </div>
        </div>
        <Row label="開團日期" value={formatShortDate(campaign.openDate)} />
        {campaign.closeDate && <Row label="結單日期" value={formatShortDate(campaign.closeDate)} />}
        {campaign.settledDate && <Row label="結團日期" value={formatShortDate(campaign.settledDate)} />}
        {campaign.notes.trim() && <Row label="備註" value={campaign.notes} />}
      </BLCard>

      {/* 結團結算 */}
      <BLCard className="space-y-3">
        <SectionHeader title="結團結算" />
        <Row label="應收" value={formatTWD(summary.receivables)} />
        <Row label="已收" value={formatTWD(summary.receivedAmount)} />
        <Row label="未收" value={formatTWD(summary.outstandingAmount)} />
        <Row label="總成本" value={formatTWD(summary.totalCost)} />
        <Row label="獲利" value={formatTWD(summary.profit)} />
        <Row label="毛利率" value={formatPercent(summary.margin)} />
        <BLProgressBar title="收款進度" value={summary.receivedRatio} trailingText={formatProgressPercent(summary.receivedRatio)} />
        <BLProgressBar title="到貨進度" value={summary.deliveryRatio} trailingText={formatProgressPercent(summary.deliveryRatio)} />
      </BLCard>

      {/* 客戶分貨 */}
      <BLCard className="space-y-3">
        <SectionHeader title="客戶分貨" />
        <BLToggle label="只看未收款" checked={unpaidOnly} onChange={setUnpaidOnly} />
        {distribution.length === 0 ? (
          <p className="py-4 text-center text-sm text-bl-tertiary-label">尚無分貨資料</p>
        ) : (
          <div className="divide-y divide-bl-separator">
            {distribution.map((row) => (
              <div key={row.name} className="py-2">
                <button
                  type="button"
                  onClick={() => toggleExpand(row.name)}
                  className="flex w-full items-center gap-2 text-left"
                >
                  {row.isFullyReceived ? (
                    <CheckCircle2 className="h-4 w-4 text-bl-green" />
                  ) : (
                    <span className="h-4 w-4 rounded-full border border-bl-tertiary-label" />
                  )}
                  <span className="flex-1 text-[15px] text-bl-label">{row.name}</span>
                  <span className="text-sm text-bl-secondary-label bl-tabular">
                    {row.totalQuantity} 件 · {formatTWD(row.totalAmount)}
                  </span>
                  <ChevronDown
                    className={cn('h-4 w-4 text-bl-tertiary-label transition', expanded.has(row.name) && 'rotate-180')}
                  />
                </button>
                {expanded.has(row.name) && (
                  <div className="mt-2 space-y-2 pl-6">
                    {row.orders.map((o) => (
                      <div key={o.id} className="flex items-center justify-between gap-2">
                        <span className="truncate text-sm text-bl-secondary-label">
                          {o.items.map((it) => it.name).join('、') || o.id}
                        </span>
                        <button
                          type="button"
                          onClick={() =>
                            setReceipt.mutate({
                              id: o.id,
                              status: o.paymentReceiptStatus === 'received' ? 'pending' : 'received',
                            })
                          }
                          className={cn(
                            'shrink-0 rounded-bl-pill px-2.5 py-1 text-xs font-semibold',
                            o.paymentReceiptStatus === 'received'
                              ? 'bg-bl-green/14 text-bl-green'
                              : 'bg-bl-fill-tertiary text-bl-secondary-label',
                          )}
                        >
                          {RECEIPT_STATUS_TITLE[o.paymentReceiptStatus]}
                        </button>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </BLCard>

      {!campaign.settledDate && (
        <BLButton variant="secondary" fullWidth onClick={() => settle.mutate(campaign.id)}>
          結團結算
        </BLButton>
      )}

      {/* 更多選單 */}
      <Sheet open={moreOpen} onClose={() => setMoreOpen(false)} title="開團操作">
        <div className="space-y-1">
          <MenuButton label="編輯" onClick={() => { setMoreOpen(false); router.push(`/campaigns/${campaign.id}/edit`); }} />
          <MenuButton label="變更狀態" onClick={() => { setMoreOpen(false); setStatusPicker(true); }} />
          {!campaign.settledDate && (
            <MenuButton label="結團結算" onClick={() => { setMoreOpen(false); settle.mutate(campaign.id); }} />
          )}
          <MenuButton label="刪除" destructive onClick={() => { setMoreOpen(false); setDeleteConfirm(true); }} />
        </div>
      </Sheet>

      <OptionPicker
        open={statusPicker}
        onClose={() => setStatusPicker(false)}
        title="開團狀態"
        searchable={false}
        options={[
          { value: 'ongoing', label: '開團中' },
          { value: 'closed', label: '已收單' },
        ]}
        selected={campaign.status}
        onSelect={(v) => setStatus.mutate({ id: campaign.id, status: v as CampaignStatus })}
      />

      <Sheet open={deleteConfirm} onClose={() => setDeleteConfirm(false)} title="刪除開團">
        <div className="space-y-4 py-2 text-center">
          <p className="text-[15px] text-bl-secondary-label">確定要刪除這個開團嗎？訂單不會被刪除。</p>
          <div className="flex gap-3">
            <BLButton variant="secondary" fullWidth onClick={() => setDeleteConfirm(false)}>
              取消
            </BLButton>
            <BLButton
              variant="destructive"
              fullWidth
              onClick={() => remove.mutate(campaign.id, { onSuccess: () => router.push('/campaigns') })}
            >
              刪除
            </BLButton>
          </div>
        </div>
      </Sheet>
    </div>
  );
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between gap-3 text-[15px]">
      <span className="shrink-0 text-bl-secondary-label">{label}</span>
      <span className="truncate text-right text-bl-label bl-tabular">{value}</span>
    </div>
  );
}

function MenuButton({
  label,
  onClick,
  destructive,
}: {
  label: string;
  onClick: () => void;
  destructive?: boolean;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        'w-full rounded-bl-sm px-3 py-3 text-left text-[15px]',
        destructive ? 'text-bl-red' : 'text-bl-label',
      )}
    >
      {label}
    </button>
  );
}
