import type { FxSnapshotDTO } from '../types';

// 顯示匯率：回傳「1 單位 currency = X TWD」；無快照或無資料回 null (空狀態，不偽造)
export function displayRate(
  snapshot: FxSnapshotDTO | null | undefined,
  currency: string,
): number | null {
  if (currency === 'TWD') return 1;
  if (!snapshot) return null;
  if (snapshot.base === 'TWD') {
    const inverse = Number(snapshot.rates[currency]);
    return inverse > 0 ? 1 / inverse : null;
  }
  if (snapshot.base === currency) {
    const twd = Number(snapshot.rates.TWD);
    return twd > 0 ? twd : null;
  }
  return null;
}

// 折合新台幣 (amount 為來源幣別金額)
export function convertToTwd(amount: number, rate: number | null): number | null {
  if (rate === null) return null;
  return amount * rate;
}
