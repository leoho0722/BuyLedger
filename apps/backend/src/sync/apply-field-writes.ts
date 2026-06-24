// 欄位級合併核心：以每欄位 HLC 時鐘逐欄合併 incoming partial patch 到 stored 實體
// 規則 (對齊 sync-conflict-resolution spec)：incoming 勝出當且僅當其時鐘嚴格大於 stored；
// 等時鐘保留 stored。不同欄位各自獨立 → 自動合併；同欄位由 HLC (p→c→writerId) 決勝
// 純函式、無副作用，供 OrdersService / CampaignsService 的所有寫入路徑共用
//
// 注意：勝出欄位儲存的是 incoming 的「client 時鐘」(含 client writerId)，刻意不重蓋成
// 伺服器時鐘——否則兩個並行同 (p,c) 但不同 writer 的寫入會被蓋成同一 writerId、退化為
// 到達順序決勝 (對抗驗證指出的缺陷)。重送相同 patch → 時鐘相等 → 保留 stored → 真 no-op

import { compareHlc, decodeHlc } from './hlc';

/** 單一欄位值；合併不檢視其結構，僅整顆覆寫或保留 */
export type FieldValue = unknown;
/** 欄位名 → 欄位值的扁平映射 (合併與比對的基本單位) */
export type FieldMap = Record<string, FieldValue>;
/** 欄位名 → 編碼後的 HLC 字串 */
export type ClockMap = Record<string, string>;

/** 一次 incoming partial patch：僅含本次變更的欄位值及其對應時鐘 */
export interface FieldPatch {
  /** 本次變更的欄位值 (僅含變更欄位) */
  changedFields: FieldMap;
  /** 對應每個變更欄位的 HLC；缺任一即 400 */
  fieldClocks: ClockMap;
}

/** 一次逐欄合併的結果：合併後狀態加上供 client 對帳與重新鏡像判斷的附帶資訊 */
export interface MergeResult {
  /** 合併後的欄位值 (stored ∪ patch) */
  values: FieldMap;
  /** 合併後的 fieldClocks */
  clocks: ClockMap;
  /** 每個被 patch 的欄位的權威時鐘 (不論勝負)，供 client 對帳清 dirty */
  appliedClocks: ClockMap;
  /** 是否有任何 stored 值/時鐘被改動 (用於判斷是否需重新鏡像) */
  changed: boolean;
}

/** 變更欄位缺少 HLC。由呼叫端轉成 400 BadRequest */
export class MissingFieldClockError extends Error {
  constructor(public readonly field: string) {
    super(`Missing HLC for changed field: ${field}`);
    this.name = 'MissingFieldClockError';
  }
}

/**
 * 將 incoming partial patch 逐欄合併進 stored
 * 未出現在 patch 的欄位保留 stored 值與時鐘不動
 */
export function mergeFieldWrites(
  storedValues: FieldMap,
  storedClocks: ClockMap,
  patch: FieldPatch,
): MergeResult {
  const values: FieldMap = { ...storedValues };
  const clocks: ClockMap = { ...storedClocks };
  const appliedClocks: ClockMap = {};
  let changed = false;

  for (const field of Object.keys(patch.changedFields)) {
    const incomingEnc = patch.fieldClocks[field];
    if (!incomingEnc) {
      throw new MissingFieldClockError(field);
    }
    const incoming = decodeHlc(incomingEnc);
    const storedEnc = storedClocks[field];
    const stored = storedEnc ? decodeHlc(storedEnc) : null;

    const incomingWins = stored === null || compareHlc(incoming, stored) > 0;
    if (incomingWins) {
      values[field] = patch.changedFields[field];
      clocks[field] = incomingEnc;
      appliedClocks[field] = incomingEnc;
      if (storedEnc !== incomingEnc) {
        changed = true;
      }
    } else {
      // incoming 落後：保留 stored；權威時鐘即 stored 時鐘 (client 據此採用伺服器值)
      appliedClocks[field] = storedEnc as string;
    }
  }

  return { values, clocks, appliedClocks, changed };
}
