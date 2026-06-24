'use client';

import { Check, Inbox, Plus } from 'lucide-react';
import { useState } from 'react';
import { cn } from '@/lib/cn';
import { BLButton } from './BLButton';
import { BLSearchField } from './BLSearchField';
import { EmptyState } from './EmptyState';
import { Sheet } from './Sheet';

export interface PickerOption {
  value: string;
  label: string;
  keywords?: string;
}

// 可重用選項挑選器：單選/多選、搜尋、清除列、新增。對齊 iOS OptionPicker 行為
export function OptionPicker({
  open,
  onClose,
  title,
  options,
  searchable = true,
  selected,
  onSelect,
  multi = false,
  selectedSet = [],
  onToggle,
  onDone,
  clearLabel,
  onClear,
  onAdd,
  addLabel = '新增',
  emptyTitle = '尚無項目',
  emptyDescription,
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  options: PickerOption[];
  searchable?: boolean;
  selected?: string;
  onSelect?: (value: string) => void;
  multi?: boolean;
  selectedSet?: string[];
  onToggle?: (value: string) => void;
  onDone?: () => void;
  clearLabel?: string;
  onClear?: () => void;
  onAdd?: (name: string) => void;
  addLabel?: string;
  emptyTitle?: string;
  emptyDescription?: string;
}) {
  const [search, setSearch] = useState('');
  const [adding, setAdding] = useState(false);
  const [addName, setAddName] = useState('');

  const q = search.trim().toLowerCase();
  const filtered = q
    ? options.filter((o) => `${o.label} ${o.keywords ?? ''}`.toLowerCase().includes(q))
    : options;

  const isSelected = (value: string) =>
    multi ? selectedSet.includes(value) : selected === value;

  const handleRow = (value: string) => {
    if (multi) {
      onToggle?.(value);
    } else {
      onSelect?.(value);
      onClose();
    }
  };

  const confirmAdd = () => {
    const name = addName.trim();
    if (!name) return;
    onAdd?.(name);
    setAddName('');
    setAdding(false);
  };

  return (
    <Sheet
      open={open}
      onClose={onClose}
      title={title}
      trailing={
        multi ? (
          <button
            type="button"
            onClick={() => {
              onDone?.();
              onClose();
            }}
            className="text-[17px] font-semibold text-bl-accent"
          >
            完成
          </button>
        ) : undefined
      }
    >
      <div className="space-y-3">
        {searchable && <BLSearchField value={search} onChange={setSearch} />}

        {onAdd &&
          (adding ? (
            <div className="flex gap-2">
              <input
                autoFocus
                value={addName}
                onChange={(e) => setAddName(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && confirmAdd()}
                placeholder="名稱"
                className="min-w-0 flex-1 rounded-bl-sm border border-bl-separator bg-bl-surface px-3 py-2 text-[15px] text-bl-label outline-none"
              />
              <BLButton variant="secondary" onClick={confirmAdd} className="min-h-[40px]">
                新增
              </BLButton>
            </div>
          ) : (
            <button
              type="button"
              onClick={() => setAdding(true)}
              className="flex w-full items-center gap-2 rounded-bl-sm bg-bl-fill-tertiary px-3 py-2.5 text-[15px] font-medium text-bl-accent"
            >
              <Plus className="h-4 w-4" />
              {addLabel}
            </button>
          ))}

        <div className="overflow-hidden rounded-bl-md border border-bl-separator bg-bl-surface">
          {clearLabel && (
            <PickerRow
              label={clearLabel}
              selected={!multi && (selected === '' || selected == null)}
              onClick={() => {
                onClear?.();
                onClose();
              }}
            />
          )}
          {filtered.map((o) => (
            <PickerRow
              key={o.value}
              label={o.label}
              selected={isSelected(o.value)}
              onClick={() => handleRow(o.value)}
            />
          ))}
          {filtered.length === 0 &&
            (clearLabel ? (
              <div className="px-3.5 py-4 text-center text-sm text-bl-tertiary-label">沒有符合的項目</div>
            ) : (
              <EmptyState icon={Inbox} title={emptyTitle} description={emptyDescription} />
            ))}
        </div>
      </div>
    </Sheet>
  );
}

function PickerRow({
  label,
  selected,
  onClick,
}: {
  label: string;
  selected: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        'flex w-full items-start justify-between gap-2 border-b border-bl-separator px-3.5 py-3 text-left last:border-b-0 transition active:bg-bl-fill-quaternary',
      )}
    >
      <span className="text-[15px] text-bl-label">{label}</span>
      {selected && <Check className="mt-0.5 h-4 w-4 shrink-0 text-bl-accent" />}
    </button>
  );
}
