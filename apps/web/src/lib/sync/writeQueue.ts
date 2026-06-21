'use client';

// 失敗重送的本機待送佇列 (對齊 sync-failure-recovery「Bounded client retry then observable
// pending or failed state」)：寫入後端失敗 (離線/網路/5xx) 時把操作存 localStorage、UI 顯示
// 待同步/失敗，連線恢復或重新載入時自動重送。重送以 client UUID upsert + 每欄位 HLC 冪等
// (後端 PATCH 對相同時鐘為 no-op)，不會重複套用。

import { api } from '../api';

const KEY = 'buyledger.sync.writeQueue';
const MAX_ATTEMPTS = 3;

export interface QueueItem {
  opId: string;
  orderId: string;
  body: { changedFields: Record<string, unknown>; fieldClocks: Record<string, string> };
  attempts: number;
  status: 'pending' | 'failed';
}

const listeners = new Set<() => void>();

function emit(): void {
  listeners.forEach((l) => l());
}

export function subscribeQueue(listener: () => void): () => void {
  listeners.add(listener);
  return () => {
    listeners.delete(listener);
  };
}

function load(): QueueItem[] {
  if (typeof window === 'undefined') return [];
  try {
    return JSON.parse(window.localStorage.getItem(KEY) ?? '[]') as QueueItem[];
  } catch {
    return [];
  }
}

// 快取快照：useSyncExternalStore 要求 getSnapshot 在未變更時回穩定參照，故只在 save 或
// 跨分頁 storage 事件時重算。
let snapshot: QueueItem[] = typeof window !== 'undefined' ? load() : [];

function save(items: QueueItem[]): void {
  if (typeof window === 'undefined') return;
  window.localStorage.setItem(KEY, JSON.stringify(items));
  snapshot = items;
  emit();
}

export function getQueue(): QueueItem[] {
  return snapshot;
}

if (typeof window !== 'undefined') {
  window.addEventListener('storage', (e) => {
    if (e.key === KEY) {
      snapshot = load();
      emit();
    }
  });
}

export function enqueueWrite(orderId: string, body: QueueItem['body']): void {
  const items = load();
  items.push({
    opId: window.crypto.randomUUID(),
    orderId,
    body,
    attempts: 0,
    status: 'pending',
  });
  save(items);
}

let draining = false;

// 逐筆重送：成功即出列；失敗累加 attempts，達上限標記 failed (仍留佇列、供手動重試)。
export async function drainQueue(): Promise<void> {
  if (draining || typeof window === 'undefined') return;
  draining = true;
  try {
    for (const item of load()) {
      try {
        await api.orders.patch(item.orderId, item.body);
        save(load().filter((i) => i.opId !== item.opId));
      } catch {
        save(
          load().map((i) =>
            i.opId === item.opId
              ? { ...i, attempts: i.attempts + 1, status: i.attempts + 1 >= MAX_ATTEMPTS ? 'failed' : 'pending' }
              : i,
          ),
        );
      }
    }
  } finally {
    draining = false;
  }
}

// 手動重試：把 failed 重設為 pending 後再 drain。
export async function retryFailed(): Promise<void> {
  save(load().map((i) => (i.status === 'failed' ? { ...i, attempts: 0, status: 'pending' } : i)));
  await drainQueue();
}
