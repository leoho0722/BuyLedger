'use client';

import { useState } from 'react';
import { useParams } from 'next/navigation';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { Inbox, Pencil, Trash2 } from 'lucide-react';
import { PageHeader } from '@/components/PageHeader';
import { BLCard } from '@/components/ds/BLCard';
import { BLButton } from '@/components/ds/BLButton';
import { BLField } from '@/components/ds/BLField';
import { BLToggle } from '@/components/ds/BLToggle';
import { BLLabelBadge } from '@/components/ds/BLBadge';
import { EmptyState } from '@/components/ds/EmptyState';
import { Sheet } from '@/components/ds/Sheet';
import { api } from '@/lib/api';
import {
  qk,
  useCategories,
  useOrderSources,
  usePaymentMethods,
  useVerificationStatuses,
} from '@/lib/queries';
import type { PaymentMethodDTO } from '@/lib/types';
import { formatNumber } from '@/lib/format';

// 主檔種類
type Kind = 'category' | 'order-source' | 'payment-method' | 'verification-status';

// 一般 (字串型) 主檔設定：標題、查詢 hook、API endpoints、空狀態文案、對應 query key
const STRING_LOOKUPS = {
  category: {
    title: '商品類別',
    useData: useCategories,
    endpoints: api.lookups.categories,
    emptyTitle: '尚無商品類別',
    queryKey: qk.categories,
  },
  'order-source': {
    title: '訂單來源',
    useData: useOrderSources,
    endpoints: api.lookups.orderSources,
    emptyTitle: '尚無訂單來源',
    queryKey: qk.orderSources,
  },
  'verification-status': {
    title: '對帳狀態',
    useData: useVerificationStatuses,
    endpoints: api.lookups.verificationStatuses,
    emptyTitle: '尚無對帳狀態',
    queryKey: qk.verificationStatuses,
  },
} as const;

// 主檔管理動態頁：依路由 kind 分流字串主檔與付款方式主檔
export default function LookupsPage() {
  const params = useParams();
  const kind = (Array.isArray(params.kind) ? params.kind[0] : params.kind) as Kind;

  if (kind === 'payment-method') return <PaymentMethodLookup />;
  return <StringLookup kind={kind} />;
}

// MARK: - 字串型主檔 (類別 / 訂單來源 / 對帳狀態)

function StringLookup({ kind }: { kind: Exclude<Kind, 'payment-method'> }) {
  const config = STRING_LOOKUPS[kind];
  const qc = useQueryClient();
  const { data } = config.useData();
  const items = data ?? [];

  // 任一異動同時失效自身與訂單 (訂單會引用這些主檔)
  const invalidate = () => {
    void qc.invalidateQueries({ queryKey: config.queryKey });
    void qc.invalidateQueries({ queryKey: qk.orders });
  };

  const addMutation = useMutation({
    mutationFn: (name: string) => config.endpoints.add(name),
    onSuccess: invalidate,
  });
  const renameMutation = useMutation({
    mutationFn: ({ oldName, newName }: { oldName: string; newName: string }) =>
      config.endpoints.rename(oldName, newName),
    onSuccess: invalidate,
  });
  const removeMutation = useMutation({
    mutationFn: (name: string) => config.endpoints.remove(name),
    onSuccess: invalidate,
  });

  // 新增 / 改名 sheet 狀態：editing 為 null 代表新增、否則為被改名的原始名稱
  const [sheetOpen, setSheetOpen] = useState(false);
  const [editing, setEditing] = useState<string | null>(null);
  const [draftName, setDraftName] = useState('');

  const openAdd = () => {
    setEditing(null);
    setDraftName('');
    setSheetOpen(true);
  };
  const openRename = (name: string) => {
    setEditing(name);
    setDraftName(name);
    setSheetOpen(true);
  };

  const trimmed = draftName.trim();
  const canSubmit = trimmed.length > 0;

  const submit = () => {
    if (!canSubmit) return;
    if (editing === null) {
      addMutation.mutate(trimmed, { onSuccess: () => setSheetOpen(false) });
    } else {
      renameMutation.mutate(
        { oldName: editing, newName: trimmed },
        { onSuccess: () => setSheetOpen(false) },
      );
    }
  };

  return (
    <div>
      <PageHeader
        title={config.title}
        action={
          <BLButton variant="secondary" onClick={openAdd}>
            新增
          </BLButton>
        }
      />

      <div className="space-y-4">
        <p className="px-1 text-[13px] text-bl-secondary-label">
          共 <span className="bl-tabular">{formatNumber(items.length)}</span> 項
        </p>

        <BLCard padded={false}>
          {items.length === 0 ? (
            <EmptyState icon={Inbox} title={config.emptyTitle} />
          ) : (
            items.map((name, index) => (
              <div
                key={name}
                className={
                  'flex items-center gap-3 px-4 py-3' +
                  (index < items.length - 1 ? ' border-b border-bl-separator' : '')
                }
              >
                <p className="min-w-0 flex-1 truncate text-[15px] text-bl-label">{name}</p>
                <button
                  type="button"
                  aria-label="改名"
                  onClick={() => openRename(name)}
                  className="shrink-0 rounded-bl-sm p-1.5 text-bl-secondary-label transition-colors hover:bg-bl-fill-quaternary"
                >
                  <Pencil className="h-[18px] w-[18px]" />
                </button>
                <button
                  type="button"
                  aria-label="刪除"
                  onClick={() => removeMutation.mutate(name)}
                  className="shrink-0 rounded-bl-sm p-1.5 text-bl-red transition-colors hover:bg-bl-fill-quaternary"
                >
                  <Trash2 className="h-[18px] w-[18px]" />
                </button>
              </div>
            ))
          )}
        </BLCard>
      </div>

      <Sheet
        open={sheetOpen}
        onClose={() => setSheetOpen(false)}
        title={editing === null ? `新增${config.title}` : '改名'}
        footer={
          <BLButton fullWidth onClick={submit} disabled={!canSubmit}>
            確認
          </BLButton>
        }
      >
        <BLField label="名稱" value={draftName} onChange={setDraftName} placeholder="輸入名稱" />
      </Sheet>
    </div>
  );
}

// MARK: - 付款方式主檔 (帶旗標)

// 付款方式編輯草稿
interface PaymentDraft {
  name: string;
  isCardless: boolean;
  isBankTransfer: boolean;
  isCashOnDelivery: boolean;
}

const EMPTY_PAYMENT_DRAFT: PaymentDraft = {
  name: '',
  isCardless: false,
  isBankTransfer: false,
  isCashOnDelivery: false,
};

function PaymentMethodLookup() {
  const qc = useQueryClient();
  const { data } = usePaymentMethods();
  const items = data ?? [];

  const invalidate = () => {
    void qc.invalidateQueries({ queryKey: qk.paymentMethods });
    void qc.invalidateQueries({ queryKey: qk.orders });
  };

  const addMutation = useMutation({
    mutationFn: (body: PaymentDraft) => api.lookups.paymentMethods.add(body),
    onSuccess: invalidate,
  });
  const updateMutation = useMutation({
    mutationFn: ({ oldName, body }: { oldName: string; body: PaymentDraft }) =>
      api.lookups.paymentMethods.update(oldName, body),
    onSuccess: invalidate,
  });
  const removeMutation = useMutation({
    mutationFn: (name: string) => api.lookups.paymentMethods.remove(name),
    onSuccess: invalidate,
  });

  // editing 為 null 代表新增、否則為被編輯的原始名稱
  const [sheetOpen, setSheetOpen] = useState(false);
  const [editing, setEditing] = useState<string | null>(null);
  const [draft, setDraft] = useState<PaymentDraft>(EMPTY_PAYMENT_DRAFT);

  const openAdd = () => {
    setEditing(null);
    setDraft(EMPTY_PAYMENT_DRAFT);
    setSheetOpen(true);
  };
  const openEdit = (pm: PaymentMethodDTO) => {
    setEditing(pm.name);
    setDraft({
      name: pm.name,
      isCardless: pm.isCardless,
      isBankTransfer: pm.isBankTransfer,
      isCashOnDelivery: pm.isCashOnDelivery,
    });
    setSheetOpen(true);
  };

  const trimmedName = draft.name.trim();
  const canSubmit = trimmedName.length > 0;

  const submit = () => {
    if (!canSubmit) return;
    const body: PaymentDraft = { ...draft, name: trimmedName };
    if (editing === null) {
      addMutation.mutate(body, { onSuccess: () => setSheetOpen(false) });
    } else {
      updateMutation.mutate({ oldName: editing, body }, { onSuccess: () => setSheetOpen(false) });
    }
  };

  // 旗標 → 標籤徽章清單
  const flagBadges = (pm: PaymentMethodDTO) => {
    const badges: string[] = [];
    if (pm.isCardless) badges.push('無卡');
    if (pm.isBankTransfer) badges.push('銀行匯款');
    if (pm.isCashOnDelivery) badges.push('貨到付款');
    return badges;
  };

  return (
    <div>
      <PageHeader
        title="付款方式"
        action={
          <BLButton variant="secondary" onClick={openAdd}>
            新增
          </BLButton>
        }
      />

      <div className="space-y-4">
        <p className="px-1 text-[13px] text-bl-secondary-label">
          共 <span className="bl-tabular">{formatNumber(items.length)}</span> 項
        </p>

        <BLCard padded={false}>
          {items.length === 0 ? (
            <EmptyState icon={Inbox} title="尚無付款方式" />
          ) : (
            items.map((pm, index) => (
              <div
                key={pm.name}
                className={
                  'flex items-center gap-3 px-4 py-3' +
                  (index < items.length - 1 ? ' border-b border-bl-separator' : '')
                }
              >
                <div className="flex min-w-0 flex-1 flex-wrap items-center gap-2">
                  <p className="truncate text-[15px] text-bl-label">{pm.name}</p>
                  {flagBadges(pm).map((label) => (
                    <BLLabelBadge key={label} label={label} tone="neutral" />
                  ))}
                </div>
                <button
                  type="button"
                  aria-label="編輯"
                  onClick={() => openEdit(pm)}
                  className="shrink-0 rounded-bl-sm p-1.5 text-bl-secondary-label transition-colors hover:bg-bl-fill-quaternary"
                >
                  <Pencil className="h-[18px] w-[18px]" />
                </button>
                <button
                  type="button"
                  aria-label="刪除"
                  onClick={() => removeMutation.mutate(pm.name)}
                  className="shrink-0 rounded-bl-sm p-1.5 text-bl-red transition-colors hover:bg-bl-fill-quaternary"
                >
                  <Trash2 className="h-[18px] w-[18px]" />
                </button>
              </div>
            ))
          )}
        </BLCard>
      </div>

      <Sheet
        open={sheetOpen}
        onClose={() => setSheetOpen(false)}
        title={editing === null ? '新增付款方式' : '編輯付款方式'}
        footer={
          <BLButton fullWidth onClick={submit} disabled={!canSubmit}>
            確認
          </BLButton>
        }
      >
        <div className="space-y-4">
          <BLField
            label="名稱"
            value={draft.name}
            onChange={(name) => setDraft((d) => ({ ...d, name }))}
            placeholder="輸入名稱"
          />
          <div className="space-y-3 rounded-bl-md border-[0.5px] border-bl-separator bg-bl-surface p-4">
            <BLToggle
              label="無卡"
              checked={draft.isCardless}
              onChange={(isCardless) => setDraft((d) => ({ ...d, isCardless }))}
            />
            <BLToggle
              label="銀行匯款"
              checked={draft.isBankTransfer}
              onChange={(isBankTransfer) => setDraft((d) => ({ ...d, isBankTransfer }))}
            />
            <BLToggle
              label="貨到付款"
              checked={draft.isCashOnDelivery}
              onChange={(isCashOnDelivery) => setDraft((d) => ({ ...d, isCashOnDelivery }))}
            />
          </div>
        </div>
      </Sheet>
    </div>
  );
}
