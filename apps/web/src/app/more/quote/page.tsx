'use client';

import { useMemo, useState } from 'react';
import { PageHeader } from '@/components/PageHeader';
import { BLCard } from '@/components/ds/BLCard';
import { BLField } from '@/components/ds/BLField';
import { BLSelectRow } from '@/components/ds/BLSelectRow';
import { OptionPicker, type PickerOption } from '@/components/ds/OptionPicker';
import { displayRate } from '@/lib/domain/fx';
import { formatPercent, formatTWD } from '@/lib/format';
import { useCurrencyCodes, useFxLatest } from '@/lib/queries';

// 報價試算頁：依匯率與各項費率推算建議售價 (對齊 iOS QuoteFeature)。
export default function QuotePage() {
  const fxQuery = useFxLatest();
  const codesQuery = useCurrencyCodes();
  const snapshot = fxQuery.data ?? null;
  const codes = codesQuery.data ?? [];

  // 表單狀態：金額/費率皆以 string 保存，計算時再轉數值。
  const [fromCurrency, setFromCurrency] = useState('JPY');
  const [itemPrice, setItemPrice] = useState('');
  const [localShipping, setLocalShipping] = useState('');
  const [intlShipping, setIntlShipping] = useState('');
  const [cardFeePercent, setCardFeePercent] = useState('');
  const [paymentFeePercent, setPaymentFeePercent] = useState('');
  const [platformFeePercent, setPlatformFeePercent] = useState('');
  const [targetMarginPercent, setTargetMarginPercent] = useState('');
  const [pickerOpen, setPickerOpen] = useState(false);

  // 1 單位來源幣別折合 TWD；無資料回 0 (結果卡顯示空狀態)。
  const rate = displayRate(snapshot, fromCurrency) ?? 0;

  // 試算 (空值當 0、NaN 防護；費率為整數百分比)。
  const result = useMemo(() => {
    const num = (s: string) => {
      const n = Number(s || 0);
      return Number.isFinite(n) ? n : 0;
    };
    const itemTwd = num(itemPrice) * rate;
    const domesticTwd = num(localShipping) * rate;
    const intlTwd = num(intlShipping);
    const cardFeeTwd = (itemTwd * num(cardFeePercent)) / 100;
    const paymentFeeTwd = (itemTwd * num(paymentFeePercent)) / 100;
    const platformFeeTwd = (itemTwd * num(platformFeePercent)) / 100;
    const costTwd = itemTwd + domesticTwd + intlTwd + cardFeeTwd + paymentFeeTwd + platformFeeTwd;
    const suggestedTwd = Math.ceil((costTwd * (1 + num(targetMarginPercent) / 100)) / 10) * 10;
    const profit = suggestedTwd - costTwd;
    const marginPct = suggestedTwd === 0 ? 0 : (profit / suggestedTwd) * 100;
    return {
      itemTwd,
      shippingTwd: domesticTwd + intlTwd,
      feeTwd: cardFeeTwd + paymentFeeTwd + platformFeeTwd,
      suggestedTwd,
      profit,
      marginPct,
    };
  }, [
    rate,
    itemPrice,
    localShipping,
    intlShipping,
    cardFeePercent,
    paymentFeePercent,
    platformFeePercent,
    targetMarginPercent,
  ]);

  const currencyOptions: PickerOption[] = codes.map((code) => ({ value: code, label: code }));

  return (
    <div>
      <PageHeader title="報價試算" />

      <div className="space-y-4">
        {/* 表單卡：幣別 + 各項金額/費率輸入。 */}
        <BLCard className="space-y-4">
          <BLSelectRow
            label="來源幣別"
            value={fromCurrency}
            onClick={() => setPickerOpen(true)}
            active={pickerOpen}
          />
          <BLField
            label={`商品單價 (${fromCurrency})`}
            value={itemPrice}
            onChange={setItemPrice}
            inputMode="decimal"
          />
          <BLField
            label={`當地運費 (${fromCurrency})`}
            value={localShipping}
            onChange={setLocalShipping}
            inputMode="decimal"
          />
          <BLField
            label="國際運費 (TWD)"
            value={intlShipping}
            onChange={setIntlShipping}
            inputMode="decimal"
          />
          <BLField
            label="刷卡手續費 (%)"
            value={cardFeePercent}
            onChange={setCardFeePercent}
            inputMode="decimal"
            suffix="%"
          />
          <BLField
            label="金流手續費 (%)"
            value={paymentFeePercent}
            onChange={setPaymentFeePercent}
            inputMode="decimal"
            suffix="%"
          />
          <BLField
            label="平台手續費 (%)"
            value={platformFeePercent}
            onChange={setPlatformFeePercent}
            inputMode="decimal"
            suffix="%"
          />
          <BLField
            label="目標利潤率 (%)"
            value={targetMarginPercent}
            onChange={setTargetMarginPercent}
            inputMode="decimal"
            suffix="%"
          />
        </BLCard>

        {/* 結果卡：無匯率顯示空狀態，否則顯示建議售價與明細。 */}
        <BLCard className="space-y-4">
          {rate === 0 ? (
            <p className="py-2 text-center text-[15px] text-bl-tertiary-label">尚無匯率資料，無法換算</p>
          ) : (
            <>
              <div className="space-y-1">
                <span className="text-xs font-semibold text-bl-accent">建議售價</span>
                <p className="bl-tabular text-[34px] font-bold leading-tight text-bl-label">
                  {formatTWD(result.suggestedTwd)}
                </p>
              </div>
              <div className="divide-y divide-bl-separator border-t border-bl-separator pt-1">
                <DetailRow label="商品" value={formatTWD(result.itemTwd)} />
                <DetailRow label="運費" value={formatTWD(result.shippingTwd)} />
                <DetailRow label="手續費" value={formatTWD(result.feeTwd)} />
                <DetailRow
                  label="預估獲利"
                  value={formatTWD(result.profit)}
                  valueClass={result.profit >= 0 ? 'text-bl-green' : 'text-bl-red'}
                />
                <DetailRow label="實際利潤率" value={formatPercent(result.marginPct / 100)} />
              </div>
            </>
          )}
        </BLCard>
      </div>

      <OptionPicker
        open={pickerOpen}
        onClose={() => setPickerOpen(false)}
        title="來源幣別"
        options={currencyOptions}
        selected={fromCurrency}
        onSelect={setFromCurrency}
      />
    </div>
  );
}

// 明細列：左標籤、右數值。
function DetailRow({
  label,
  value,
  valueClass,
}: {
  label: string;
  value: string;
  valueClass?: string;
}) {
  return (
    <div className="flex items-center justify-between py-2.5">
      <span className="text-[15px] text-bl-secondary-label">{label}</span>
      <span className={`bl-tabular text-[15px] font-semibold ${valueClass ?? 'text-bl-label'}`}>{value}</span>
    </div>
  );
}
