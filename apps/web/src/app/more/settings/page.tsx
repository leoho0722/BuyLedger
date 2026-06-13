'use client';

import { useEffect, useState } from 'react';
import { PageHeader } from '@/components/PageHeader';
import { BLCard } from '@/components/ds/BLCard';
import { SectionHeader } from '@/components/ds/SectionHeader';
import { BLSegmentedControl } from '@/components/ds/BLSegmentedControl';
import { BLToggle } from '@/components/ds/BLToggle';
import { BLSelectRow } from '@/components/ds/BLSelectRow';
import { OptionPicker } from '@/components/ds/OptionPicker';
import { BLField } from '@/components/ds/BLField';
import { useSettings, useSettingsMutation, useCurrencyCodes } from '@/lib/queries';
import { useTheme } from '@/lib/theme';

export default function SettingsPage() {
  const settings = useSettings();
  const s = settings.data;
  const save = useSettingsMutation();
  const { appearance, setAppearance } = useTheme();
  const currencyCodes = useCurrencyCodes().data ?? [];

  // 每月獲利目標本地鏡射，blur 時才寫回。
  const [goalLocal, setGoalLocal] = useState('');
  // 挑選器開關。
  const [modelPickerOpen, setModelPickerOpen] = useState(false);
  const [currencyPickerOpen, setCurrencyPickerOpen] = useState(false);

  // settings 載入後同步初始值。
  useEffect(() => {
    if (s) setGoalLocal(s.monthlyProfitGoal);
  }, [s?.monthlyProfitGoal]); // eslint-disable-line react-hooks/exhaustive-deps

  if (settings.isLoading || !s) {
    return (
      <>
        <PageHeader title="設定" />
        <p className="text-bl-secondary-label">載入中…</p>
      </>
    );
  }

  return (
    <>
      <PageHeader title="設定" />

      <div className="space-y-4">
        {/* 外觀 */}
        <div className="space-y-2">
          <SectionHeader title="外觀" />
          <BLCard>
            <BLSegmentedControl
              value={appearance}
              onChange={setAppearance}
              options={[
                { value: 'system', label: '系統' },
                { value: 'light', label: '淺色' },
                { value: 'dark', label: '深色' },
              ]}
            />
          </BLCard>
        </div>

        {/* 通知 */}
        <div className="space-y-2">
          <SectionHeader title="通知" />
          <BLCard>
            <BLToggle
              label="啟用通知"
              checked={s.notifications}
              onChange={(v) => save.mutate({ notifications: v })}
            />
          </BLCard>
        </div>

        {/* AI 商品總結 */}
        <div className="space-y-2">
          <SectionHeader title="AI 商品明細總結" />
          <BLCard>
            <div className="space-y-3">
              <BLToggle
                label="啟用 AI 總結"
                checked={s.useAiSummary}
                onChange={(v) => save.mutate({ useAiSummary: v })}
              />
              <BLSelectRow
                label="模型"
                value={s.aiSummaryModel}
                active={modelPickerOpen}
                onClick={() => setModelPickerOpen(true)}
              />
            </div>
          </BLCard>
        </div>

        {/* 預設幣別 */}
        <div className="space-y-2">
          <SectionHeader title="預設幣別" />
          <BLCard>
            <BLSelectRow
              label="預設幣別"
              value={s.defaultCurrency}
              active={currencyPickerOpen}
              onClick={() => setCurrencyPickerOpen(true)}
            />
          </BLCard>
        </div>

        {/* 每月獲利目標 */}
        <div className="space-y-2">
          <SectionHeader title="月度淨獲利目標" />
          <BLCard>
            <div
              onBlur={() => {
                // 失焦時寫回，避免逐字觸發 mutation。
                if (goalLocal !== s.monthlyProfitGoal) {
                  save.mutate({ monthlyProfitGoal: goalLocal });
                }
              }}
            >
              <BLField
                label="月度淨獲利目標 (TWD)"
                inputMode="decimal"
                value={goalLocal}
                onChange={setGoalLocal}
              />
            </div>
          </BLCard>
        </div>
      </div>

      {/* AI 模型挑選器 */}
      <OptionPicker
        open={modelPickerOpen}
        onClose={() => setModelPickerOpen(false)}
        title="選擇模型"
        options={s.aiModelCandidates.map((m) => ({ value: m, label: m }))}
        selected={s.aiSummaryModel}
        onSelect={(m) => save.mutate({ aiSummaryModel: m })}
      />

      {/* 預設幣別挑選器 */}
      <OptionPicker
        open={currencyPickerOpen}
        onClose={() => setCurrencyPickerOpen(false)}
        title="選擇幣別"
        options={currencyCodes.map((c) => ({ value: c, label: c }))}
        selected={s.defaultCurrency}
        onSelect={(c) => save.mutate({ defaultCurrency: c })}
      />
    </>
  );
}
