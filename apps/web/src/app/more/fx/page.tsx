'use client';

import { useState } from 'react';
import { Coins, RotateCw } from 'lucide-react';
import { BLAmountField } from '@/components/ds/BLField';
import { BLButton } from '@/components/ds/BLButton';
import { BLCard } from '@/components/ds/BLCard';
import { BLSelectRow } from '@/components/ds/BLSelectRow';
import { EmptyState } from '@/components/ds/EmptyState';
import { OptionPicker } from '@/components/ds/OptionPicker';
import { PageHeader } from '@/components/PageHeader';
import { FX_QUICK_AMOUNTS } from '@/lib/domain/constants';
import { displayRate } from '@/lib/domain/fx';
import { formatNumber, formatTWD } from '@/lib/format';
import { useCurrencyCodes, useFxLatest, useFxRefresh, useSettings } from '@/lib/queries';

export default function FxToolPage() {
  // 資料層。
  const fxQuery = useFxLatest();
  const snapshot = fxQuery.data;
  const codes = useCurrencyCodes().data ?? [];
  useSettings();
  const fxRefresh = useFxRefresh();

  // 互動狀態。
  const [fromCurrency, setFromCurrency] = useState('JPY');
  const [amount, setAmount] = useState('10000');
  const [pickerOpen, setPickerOpen] = useState(false);

  // 重新整理鈕 (轉圈圖示，refresh 進行中淡出鎖定)。
  const refreshButton = (
    <BLButton
      variant="plain"
      onClick={() => fxRefresh.mutate()}
      disabled={fxRefresh.isPending}
      aria-label="重新整理匯率"
    >
      <RotateCw className="h-5 w-5" />
    </BLButton>
  );

  // 載入中 → 不要閃現空狀態 (區分「載入中」與「無資料」)。
  if (fxQuery.isLoading) {
    return (
      <div>
        <PageHeader title="匯率工具" action={refreshButton} />
        <p className="py-12 text-center text-bl-secondary-label">載入中…</p>
      </div>
    );
  }

  // 載入完成仍無快照 → 空狀態 (不偽造匯率)。
  if (!snapshot) {
    return (
      <div>
        <PageHeader title="匯率工具" action={refreshButton} />
        <BLCard>
          <EmptyState
            icon={Coins}
            title="尚無可用匯率資料"
            description="設定 EXCHANGE_RATE_API_KEY 後重新整理"
          />
        </BLCard>
      </div>
    );
  }

  // 來源幣別對 TWD 的匯率 (null 代表無資料)。
  const rate = displayRate(snapshot, fromCurrency);
  const amountValue = Number(amount);
  const safeAmount = Number.isFinite(amountValue) ? amountValue : 0;

  return (
    <div>
      <PageHeader title="匯率工具" action={refreshButton} />

      <div className="space-y-4">
        {/* 來源幣別挑選 */}
        <BLSelectRow
          label="來源幣別"
          value={fromCurrency}
          onClick={() => setPickerOpen(true)}
          active={pickerOpen}
        />
        <OptionPicker
          open={pickerOpen}
          onClose={() => setPickerOpen(false)}
          title="選擇幣別"
          options={codes.map((c) => ({ value: c, label: c }))}
          selected={fromCurrency}
          onSelect={setFromCurrency}
        />

        {/* 金額輸入 */}
        <BLAmountField
          label="金額"
          value={amount}
          onChange={setAmount}
          currencyLabel={fromCurrency}
        />

        {/* 換算結果 */}
        <BLCard>
          {rate === null ? (
            <p className="text-center text-[22px] font-bold text-bl-tertiary-label bl-tabular">—</p>
          ) : (
            <div className="space-y-1 text-center">
              <p className="text-[26px] font-bold text-bl-label bl-tabular">
                = 新台幣 {formatTWD(safeAmount * rate)}
              </p>
              <p className="text-[13px] text-bl-secondary-label bl-tabular">
                1 {fromCurrency} = {formatNumber(rate, 4)} TWD
              </p>
            </div>
          )}
        </BLCard>

        {/* 快捷金額 */}
        <div className="flex flex-wrap gap-2">
          {FX_QUICK_AMOUNTS.map((n) => (
            <BLButton
              key={n}
              variant="secondary"
              onClick={() => setAmount(String(n))}
              className="flex-1 bl-tabular"
            >
              {formatNumber(n)}
            </BLButton>
          ))}
        </div>

        {/* 全部幣別匯率列表 */}
        <BLCard padded={false} className="max-h-[420px] overflow-y-auto">
          {codes.map((code) => {
            const r = displayRate(snapshot, code);
            return (
              <div
                key={code}
                className="flex items-center justify-between gap-2 border-b border-bl-separator px-4 py-3 last:border-b-0"
              >
                <span className="text-[15px] font-medium text-bl-label bl-tabular">{code}</span>
                <span className="text-[15px] text-bl-secondary-label bl-tabular">
                  1 {code} = {r === null ? '—' : formatNumber(r, 4)} TWD
                </span>
              </div>
            );
          })}
        </BLCard>
      </div>
    </div>
  );
}
