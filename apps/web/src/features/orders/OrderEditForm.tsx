'use client';

import { Plus, Trash2, X } from 'lucide-react';
import { useMemo, useRef, useState } from 'react';
import { BLAmountField, BLField } from '@/components/ds/BLField';
import { BLButton } from '@/components/ds/BLButton';
import { BLCard } from '@/components/ds/BLCard';
import { BLListRow } from '@/components/ds/BLListRow';
import { BLSegmentedControl } from '@/components/ds/BLSegmentedControl';
import { BLSelectRow } from '@/components/ds/BLSelectRow';
import { BLToggle } from '@/components/ds/BLToggle';
import { OptionPicker, type PickerOption } from '@/components/ds/OptionPicker';
import { SectionHeader } from '@/components/ds/SectionHeader';
import { api, type OrderInputBody } from '@/lib/api';
import { cn } from '@/lib/cn';
import {
  CUSTOMER_TIER_TITLE,
  MAX_PHOTO_COUNT,
  ORDER_STATUS_ORDER,
  ORDER_STATUS_TITLE,
} from '@/lib/domain/constants';
import {
  useCampaigns,
  useCategories,
  useCurrencyCodes,
  useOrderMutations,
  useOrderSources,
  usePaymentMethods,
  useSettings,
  useVerificationStatuses,
} from '@/lib/queries';
import type { CustomerTier, OrderDTO, OrderStatus, PaymentReceiptStatus } from '@/lib/types';
import { fileToNormalizedDataUrl } from './photoUtils';

type PickerKind =
  | 'currency'
  | 'orderSource'
  | 'category'
  | 'paymentMethod'
  | 'verification'
  | 'campaign'
  | 'status'
  | 'tier'
  | null;

interface ItemDraft {
  id?: string;
  name: string;
  quantity: string;
  unitPrice: string;
}

export interface OrderFormInitial extends Partial<OrderInputBody> {
  id?: string;
}

// 訂單編輯表單 (新增/編輯共用)。合併模式 (mergedSourceIDs 非空) 時類別/開團改多選。
export function OrderEditForm({
  mode,
  orderId,
  initial,
  onSaved,
  onCancel,
}: {
  mode: 'create' | 'edit';
  orderId?: string;
  initial?: OrderFormInitial;
  onSaved: (order: OrderDTO) => void;
  onCancel: () => void;
}) {
  const categories = useCategories().data ?? [];
  const orderSources = useOrderSources().data ?? [];
  const paymentMethods = usePaymentMethods().data ?? [];
  const verificationStatuses = useVerificationStatuses().data ?? [];
  const campaigns = useCampaigns().data ?? [];
  const currencyCodes = useCurrencyCodes().data ?? [];
  const settings = useSettings().data;
  const { create, update } = useOrderMutations();

  const mergeMode = (initial?.mergedSourceIDs?.length ?? 0) > 0;

  const [customerName, setCustomerName] = useState(initial?.customer?.name ?? '');
  const [tier, setTier] = useState<CustomerTier>(initial?.customer?.tier ?? 'new');
  const [currency, setCurrency] = useState(initial?.currency ?? settings?.defaultCurrency ?? 'TWD');
  const [date] = useState(initial?.date ?? new Date().toISOString());
  const [status, setStatus] = useState<OrderStatus>(initial?.status ?? 'quoting');
  const [orderSource, setOrderSource] = useState(initial?.orderSource ?? '');
  const [cats, setCats] = useState<string[]>(initial?.categories ?? []);
  const [paymentMethod, setPaymentMethod] = useState(initial?.paymentMethod ?? '');
  const [verificationStatus, setVerificationStatus] = useState(initial?.verificationStatus ?? '');
  const [campaignNames, setCampaignNames] = useState<string[]>(initial?.campaignNames ?? []);
  const [receipt, setReceipt] = useState<PaymentReceiptStatus>(initial?.paymentReceiptStatus ?? 'pending');
  const [items, setItems] = useState<ItemDraft[]>(
    initial?.items?.map((it) => ({
      id: it.id,
      name: it.name ?? '',
      quantity: String(it.quantity ?? 1),
      unitPrice: it.unitPrice ?? '',
    })) ?? [{ name: '', quantity: '1', unitPrice: '' }],
  );
  const [chargedAmount, setCharged] = useState(initial?.chargedAmount ?? '');
  const [itemCost, setItemCost] = useState(initial?.itemCost ?? '');
  const [domesticShipping, setDomestic] = useState(initial?.domesticShipping ?? '');
  const [internationalShipping, setInternational] = useState(initial?.internationalShipping ?? '');
  const [foreignDomesticShipping, setForeignDomestic] = useState(initial?.foreignDomesticShipping ?? '');
  const [cardFeePercent, setCardFeePercent] = useState(fractionToPercent(initial?.cardFeeRate));
  const [platformFeePercent, setPlatformFeePercent] = useState(fractionToPercent(initial?.platformFeeRate));
  const [paymentFeePercent, setPaymentFeePercent] = useState(fractionToPercent(initial?.paymentFeeRate));
  const [cardlessDeduction, setCardlessDeduction] = useState(initial?.cardlessDeductionAmount ?? '');
  const [cardlessSupplement, setCardlessSupplement] = useState(initial?.cardlessSupplementAmount ?? '');
  const [photos, setPhotos] = useState<string[]>(initial?.photos ?? []);
  const [notes, setNotes] = useState(initial?.notes ?? '');

  const [picker, setPicker] = useState<PickerKind>(null);
  const fileInput = useRef<HTMLInputElement>(null);

  const selectedPm = paymentMethods.find((p) => p.name === paymentMethod);
  const isCardless = selectedPm?.isCardless ?? false;
  const showVerification = isCardless || (selectedPm?.isBankTransfer ?? false);

  // 開團選單：開團中 + 已指派 (即使已收單)。
  const campaignOptions: PickerOption[] = useMemo(
    () =>
      campaigns
        .filter((c) => c.status === 'ongoing' || campaignNames.includes(c.name))
        .map((c) => ({ value: c.name, label: c.name })),
    [campaigns, campaignNames],
  );

  const canSave = cats.length > 0 && customerName.trim().length > 0;

  const submit = () => {
    const body: OrderInputBody = {
      id: orderId,
      customer: { name: customerName, tier },
      status,
      currency,
      date,
      items: items
        .filter((it) => it.name.trim() || it.unitPrice)
        .map((it) => ({
          id: it.id,
          name: it.name,
          quantity: Math.max(0, Math.trunc(Number(it.quantity) || 0)),
          unitPrice: it.unitPrice || '0',
        })),
      itemCost: itemCost || '0',
      domesticShipping: domesticShipping || '0',
      internationalShipping: internationalShipping || '0',
      foreignDomesticShipping: foreignDomesticShipping || '0',
      cardFeeRate: percentToFraction(cardFeePercent),
      platformFeeRate: percentToFraction(platformFeePercent),
      paymentFeeRate: percentToFraction(paymentFeePercent),
      chargedAmount: chargedAmount || '0',
      cardlessDeductionAmount: cardlessDeduction || '0',
      cardlessSupplementAmount: cardlessSupplement || '0',
      orderSource,
      categories: cats,
      paymentMethod,
      notes,
      verificationStatus,
      campaignNames,
      paymentReceiptStatus: receipt,
      photos,
      mergedSourceIDs: initial?.mergedSourceIDs ?? [],
    };
    if (mode === 'create') {
      create.mutate(body, { onSuccess: onSaved });
    } else {
      update.mutate({ id: orderId as string, body }, { onSuccess: onSaved });
    }
  };

  const addPhotos = async (files: FileList | null) => {
    if (!files) return;
    const remaining = MAX_PHOTO_COUNT - photos.length;
    const picked = Array.from(files).slice(0, remaining);
    const results = await Promise.all(picked.map((f) => fileToNormalizedDataUrl(f)));
    setPhotos((prev) => [...prev, ...results.filter((r): r is string => Boolean(r))].slice(0, MAX_PHOTO_COUNT));
  };

  const pending = create.isPending || update.isPending;

  return (
    <div className="space-y-4 pb-4">
      {/* 客戶 */}
      <BLCard className="space-y-3">
        <SectionHeader title="客戶" />
        <BLField label="客戶名稱" value={customerName} onChange={setCustomerName} placeholder="必填" />
        <div className="space-y-1">
          <span className="text-xs font-semibold text-bl-secondary-label">客戶分級</span>
          <BLSegmentedControl
            value={tier}
            onChange={setTier}
            options={(['new', 'regular', 'vip'] as CustomerTier[]).map((t) => ({
              value: t,
              label: CUSTOMER_TIER_TITLE[t],
            }))}
          />
        </div>
      </BLCard>

      {/* 商品明細 */}
      <BLCard className="space-y-3">
        <SectionHeader
          title="商品明細"
          action={
            <button
              type="button"
              onClick={() => setItems((prev) => [...prev, { name: '', quantity: '1', unitPrice: '' }])}
              className="flex items-center gap-1 text-[15px] text-bl-accent"
            >
              <Plus className="h-4 w-4" />
              新增
            </button>
          }
        />
        {items.map((it, i) => (
          <div key={i} className="flex items-end gap-2">
            <div className="flex-1">
              <BLField
                label={`品項 ${i + 1}`}
                value={it.name}
                onChange={(v) => updateItem(setItems, i, { name: v })}
                placeholder="商品名稱"
              />
            </div>
            <div className="w-16">
              <BLField label="數量" value={it.quantity} onChange={(v) => updateItem(setItems, i, { quantity: v })} inputMode="numeric" />
            </div>
            <div className="w-24">
              <BLField label="單價" value={it.unitPrice} onChange={(v) => updateItem(setItems, i, { unitPrice: v })} inputMode="decimal" />
            </div>
            <button
              type="button"
              onClick={() => setItems((prev) => prev.filter((_, idx) => idx !== i))}
              className="mb-2.5 text-bl-red"
              aria-label="刪除品項"
            >
              <Trash2 className="h-4 w-4" />
            </button>
          </div>
        ))}
      </BLCard>

      {/* 金額與成本 */}
      <BLCard className="space-y-3">
        <SectionHeader title="金額與成本" />
        <BLAmountField label="收款金額 (TWD)" value={chargedAmount} onChange={setCharged} currencyLabel="TWD" />
        <div className="grid grid-cols-2 gap-3">
          <BLField label="商品成本 (TWD)" value={itemCost} onChange={setItemCost} inputMode="decimal" />
          <BLField label="國內運費" value={domesticShipping} onChange={setDomestic} inputMode="decimal" />
          <BLField label="國際運費" value={internationalShipping} onChange={setInternational} inputMode="decimal" />
          <BLField label="來源國當地運費" value={foreignDomesticShipping} onChange={setForeignDomestic} inputMode="decimal" />
        </div>
        <div className="grid grid-cols-3 gap-3">
          <BLField label="刷卡費率 (%)" value={cardFeePercent} onChange={setCardFeePercent} inputMode="decimal" />
          <BLField label="平台費率 (%)" value={platformFeePercent} onChange={setPlatformFeePercent} inputMode="decimal" />
          <BLField label="金流費率 (%)" value={paymentFeePercent} onChange={setPaymentFeePercent} inputMode="decimal" />
        </div>
        {isCardless && (
          <div className="grid grid-cols-2 gap-3">
            <BLField label="無卡折抵金額" value={cardlessDeduction} onChange={setCardlessDeduction} inputMode="decimal" />
            <BLField label="無卡補款金額" value={cardlessSupplement} onChange={setCardlessSupplement} inputMode="decimal" />
          </div>
        )}
      </BLCard>

      {/* 歸屬與狀態 */}
      <BLCard className="space-y-3">
        <SectionHeader title="歸屬與狀態" />
        <BLSelectRow label="幣別" value={currency} onClick={() => setPicker('currency')} />
        <BLSelectRow
          label="商品類別 (至少一個)"
          value={cats.join('、')}
          placeholder="請選擇"
          active={cats.length === 0}
          onClick={() => setPicker('category')}
        />
        <BLSelectRow label="訂單來源" value={orderSource} onClick={() => setPicker('orderSource')} />
        <BLSelectRow label="付款方式" value={paymentMethod} onClick={() => setPicker('paymentMethod')} />
        {showVerification && (
          <BLSelectRow
            label="對帳狀態"
            value={verificationStatus}
            placeholder="尚未設定"
            onClick={() => setPicker('verification')}
          />
        )}
        <BLSelectRow
          label="歸屬開團"
          value={campaignNames.join('、')}
          placeholder="未歸團"
          onClick={() => setPicker('campaign')}
        />
        <BLSelectRow label="訂單狀態" value={ORDER_STATUS_TITLE[status]} onClick={() => setPicker('status')} />
        <div className="space-y-1">
          <span className="text-xs font-semibold text-bl-secondary-label">收款狀態</span>
          <BLSegmentedControl
            value={receipt}
            onChange={setReceipt}
            options={[
              { value: 'pending', label: '待收款' },
              { value: 'received', label: '已收款' },
            ]}
          />
        </div>
      </BLCard>

      {/* 照片 */}
      <BLCard className="space-y-3">
        <SectionHeader title={`訂單照片 (${photos.length}/${MAX_PHOTO_COUNT})`} />
        <div className="flex flex-wrap gap-2">
          {photos.map((src, i) => (
            <div key={i} className="relative h-20 w-20 overflow-hidden rounded-bl-sm">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src={src} alt={`照片 ${i + 1}`} className="h-full w-full object-cover" />
              <button
                type="button"
                onClick={() => setPhotos((prev) => prev.filter((_, idx) => idx !== i))}
                className="absolute right-1 top-1 rounded-full bg-black/60 p-0.5 text-white"
                aria-label="刪除照片"
              >
                <X className="h-3 w-3" />
              </button>
            </div>
          ))}
          {photos.length < MAX_PHOTO_COUNT && (
            <button
              type="button"
              onClick={() => fileInput.current?.click()}
              className="flex h-20 w-20 items-center justify-center rounded-bl-sm border border-dashed border-bl-separator text-bl-secondary-label"
            >
              <Plus className="h-6 w-6" />
            </button>
          )}
        </div>
        <input
          ref={fileInput}
          type="file"
          accept="image/*"
          multiple
          hidden
          onChange={(e) => void addPhotos(e.target.files)}
        />
      </BLCard>

      {/* 備註 */}
      <BLCard>
        <BLField label="備註" value={notes} onChange={setNotes} multiline placeholder="選填" />
      </BLCard>

      <div className="flex gap-3">
        <BLButton variant="secondary" fullWidth onClick={onCancel}>
          取消
        </BLButton>
        <BLButton fullWidth onClick={submit} disabled={!canSave || pending}>
          {pending ? '儲存中…' : '儲存'}
        </BLButton>
      </div>

      {/* Pickers */}
      <OptionPicker
        open={picker === 'currency'}
        onClose={() => setPicker(null)}
        title="選擇幣別"
        options={currencyCodes.map((c) => ({ value: c, label: c }))}
        selected={currency}
        onSelect={setCurrency}
      />
      <OptionPicker
        open={picker === 'category'}
        onClose={() => setPicker(null)}
        title="商品類別"
        options={categories.map((c) => ({ value: c, label: c }))}
        multi={mergeMode}
        selected={cats[0]}
        selectedSet={cats}
        onSelect={(v) => setCats([v])}
        onToggle={(v) => setCats((prev) => (prev.includes(v) ? prev.filter((x) => x !== v) : [...prev, v]))}
        onAdd={async (name) => {
          await api.lookups.categories.add(name);
          setCats((prev) => (mergeMode ? [...prev, name] : [name]));
        }}
        emptyTitle="尚無商品類別"
      />
      <OptionPicker
        open={picker === 'orderSource'}
        onClose={() => setPicker(null)}
        title="訂單來源"
        options={orderSources.map((c) => ({ value: c, label: c }))}
        selected={orderSource}
        onSelect={setOrderSource}
        onAdd={async (name) => {
          await api.lookups.orderSources.add(name);
          setOrderSource(name);
        }}
        emptyTitle="尚無訂單來源"
      />
      <OptionPicker
        open={picker === 'paymentMethod'}
        onClose={() => setPicker(null)}
        title="付款方式"
        options={paymentMethods.map((p) => ({ value: p.name, label: p.name }))}
        selected={paymentMethod}
        onSelect={setPaymentMethod}
        onAdd={async (name) => {
          await api.lookups.paymentMethods.add({ name });
          setPaymentMethod(name);
        }}
        emptyTitle="尚無付款方式"
      />
      <OptionPicker
        open={picker === 'verification'}
        onClose={() => setPicker(null)}
        title="對帳狀態"
        options={verificationStatuses.map((c) => ({ value: c, label: c }))}
        selected={verificationStatus}
        onSelect={setVerificationStatus}
        onAdd={async (name) => {
          await api.lookups.verificationStatuses.add(name);
          setVerificationStatus(name);
        }}
        emptyTitle="尚無對帳狀態"
      />
      <OptionPicker
        open={picker === 'campaign'}
        onClose={() => setPicker(null)}
        title="歸屬開團"
        options={campaignOptions}
        multi={mergeMode}
        selected={campaignNames[0] ?? ''}
        selectedSet={campaignNames}
        clearLabel="未歸團"
        onClear={() => setCampaignNames([])}
        onSelect={(v) => setCampaignNames([v])}
        onToggle={(v) =>
          setCampaignNames((prev) => (prev.includes(v) ? prev.filter((x) => x !== v) : [...prev, v]))
        }
        emptyTitle="尚無開團中團購"
      />
      <OptionPicker
        open={picker === 'status'}
        onClose={() => setPicker(null)}
        title="訂單狀態"
        searchable={false}
        options={ORDER_STATUS_ORDER.filter((s) => s !== 'merged' || status === 'merged').map((s) => ({
          value: s,
          label: ORDER_STATUS_TITLE[s],
        }))}
        selected={status}
        onSelect={(v) => setStatus(v as OrderStatus)}
      />
    </div>
  );
}

function updateItem(
  setItems: React.Dispatch<React.SetStateAction<ItemDraft[]>>,
  index: number,
  patch: Partial<ItemDraft>,
): void {
  setItems((prev) => prev.map((it, i) => (i === index ? { ...it, ...patch } : it)));
}

function fractionToPercent(value: string | undefined): string {
  if (!value) return '';
  const n = Number(value);
  if (!Number.isFinite(n) || n === 0) return '';
  return String(Number((n * 100).toFixed(6)));
}

function percentToFraction(percent: string): string {
  const n = Number(percent);
  if (!Number.isFinite(n)) return '0';
  return String(n / 100);
}
