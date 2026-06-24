'use client';

import { useState } from 'react';
import { BLButton } from '@/components/ds/BLButton';
import { BLCard } from '@/components/ds/BLCard';
import { BLField } from '@/components/ds/BLField';
import { BLToggle } from '@/components/ds/BLToggle';
import type { CampaignInputBody } from '@/lib/api';
import { useCampaignMutations } from '@/lib/queries';
import type { Campaign } from '@/lib/types';

export interface CampaignFormInitial {
  name?: string;
  openDate?: string;
  closeDate?: string | null;
  notes?: string;
}

// 開團編輯表單 (新增/編輯共用)
export function CampaignEditForm({
  mode,
  campaignId,
  initial,
  onSaved,
  onCancel,
}: {
  mode: 'create' | 'edit';
  campaignId?: string;
  initial?: CampaignFormInitial;
  onSaved: (campaign: Campaign) => void;
  onCancel: () => void;
}) {
  const { create, update } = useCampaignMutations();
  const [name, setName] = useState(initial?.name ?? '');
  const [openDate, setOpenDate] = useState(toDateInput(initial?.openDate ?? new Date().toISOString()));
  const [hasClose, setHasClose] = useState(Boolean(initial?.closeDate));
  const [closeDate, setCloseDate] = useState(initial?.closeDate ? toDateInput(initial.closeDate) : '');
  const [notes, setNotes] = useState(initial?.notes ?? '');

  const pending = create.isPending || update.isPending;
  const canSave = name.trim().length > 0;

  const submit = () => {
    const body: CampaignInputBody = {
      name,
      openDate: fromDateInput(openDate),
      closeDate: hasClose && closeDate ? fromDateInput(closeDate) : null,
      notes,
    };
    if (mode === 'create') create.mutate(body, { onSuccess: onSaved });
    else update.mutate({ id: campaignId as string, body }, { onSuccess: onSaved });
  };

  return (
    <div className="space-y-4">
      <BLCard className="space-y-3">
        <BLField label="開團名稱" value={name} onChange={setName} placeholder="必填" />
        <label className="block space-y-1">
          <span className="text-xs font-semibold text-bl-secondary-label">開團日期</span>
          <input
            type="date"
            value={openDate}
            onChange={(e) => setOpenDate(e.target.value)}
            className="w-full rounded-bl-sm border border-bl-separator bg-bl-surface px-3 py-2.5 text-[15px] text-bl-label outline-none"
          />
        </label>
        <BLToggle label="設定結單日期" checked={hasClose} onChange={setHasClose} />
        {hasClose && (
          <label className="block space-y-1">
            <span className="text-xs font-semibold text-bl-secondary-label">結單日期 (過期自動收單)</span>
            <input
              type="date"
              value={closeDate}
              onChange={(e) => setCloseDate(e.target.value)}
              className="w-full rounded-bl-sm border border-bl-separator bg-bl-surface px-3 py-2.5 text-[15px] text-bl-label outline-none"
            />
          </label>
        )}
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
    </div>
  );
}

function toDateInput(iso: string): string {
  const d = new Date(iso);
  const m = `${d.getMonth() + 1}`.padStart(2, '0');
  const day = `${d.getDate()}`.padStart(2, '0');
  return `${d.getFullYear()}-${m}-${day}`;
}

function fromDateInput(value: string): string {
  return new Date(`${value}T00:00:00`).toISOString();
}
