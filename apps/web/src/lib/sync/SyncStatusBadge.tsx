'use client';

import { useEffect, useSyncExternalStore } from 'react';

import { drainQueue, getQueue, retryFailed, subscribeQueue } from './writeQueue';

// 待送佇列的可觀察狀態 (對齊 sync-failure-recovery)：佇列非空時於右下角顯示「待同步 N 筆」
// 或「同步失敗 N 筆」與「重試」。掛載時與連線恢復 (window online) 時自動 drain
export function SyncStatusBadge() {
  const queue = useSyncExternalStore(subscribeQueue, getQueue, () => []);

  useEffect(() => {
    void drainQueue();
    const onOnline = () => void drainQueue();
    window.addEventListener('online', onOnline);
    return () => window.removeEventListener('online', onOnline);
  }, []);

  if (queue.length === 0) return null;

  // 依狀態拆兩種計數：failed 達重試上限 (需手動重試)、其餘皆視為 pending (待自動重送)
  const failed = queue.filter((q) => q.status === 'failed').length;
  const pending = queue.length - failed;

  return (
    <div className="bl-card-shadow fixed bottom-4 right-4 z-50 flex items-center gap-3 rounded-bl-md border border-bl-separator bg-bl-surface px-4 py-2 text-sm">
      {pending > 0 && (
        <span className="flex items-center gap-1.5 text-bl-secondary-label">
          <span className="size-2 animate-pulse rounded-bl-pill bg-bl-orange" />
          待同步 {pending} 筆
        </span>
      )}
      {failed > 0 && <span className="font-medium text-bl-red">同步失敗 {failed} 筆</span>}
      <button
        type="button"
        onClick={() => void retryFailed()}
        className="rounded-bl-sm border border-bl-separator px-2 py-0.5 text-bl-label transition hover:bg-bl-fill"
      >
        重試
      </button>
    </div>
  );
}
