// 跨裝置同步的 Hybrid Logical Clock (HLC) 基礎型別與純函式
// 規格與跨平台 conformance vectors 見 shared/sync-conformance/
// 後端 writerId 一律為字面 'server'；client 各自帶每安裝穩定 id

export interface Hlc {
  /** 物理毫秒 (epoch millis) */
  p: number;
  /** 邏輯計數器 (同一毫秒內的因果序) */
  c: number;
  /** 寫入者識別 (決勝最後一關)。後端為 'server' */
  w: string;
}

/** 後端 writerId：所有伺服器端產生的時鐘以此為來源 */
export const SERVER_WRITER_ID = 'server';

/** 物理時間欄寬 (13 位足以涵蓋到約西元 2286 年的 epoch 毫秒) */
const P_WIDTH = 13;

/** 邏輯計數器欄寬 (上限 999999) */
const C_WIDTH = 6;

/** 未來時鐘容忍度 (毫秒)：超過此界的 incoming 視為偏移、由後端拒絕 */
export const SKEW_TOLERANCE_MS = 5 * 60 * 1000;

function pad(value: number, width: number): string {
  const s = String(value);
  return s.length >= width ? s : '0'.repeat(width - s.length) + s;
}

/** 序列化為可排序字串 `p(13):c(6):w`，使字典序等同因果序 */
export function encodeHlc(h: Hlc): string {
  return `${pad(h.p, P_WIDTH)}:${pad(h.c, C_WIDTH)}:${h.w}`;
}

/** 反序列化 `p:c:w`；writerId 不含冒號 */
export function decodeHlc(s: string): Hlc {
  const i1 = s.indexOf(':');
  const i2 = s.indexOf(':', i1 + 1);
  if (i1 < 0 || i2 < 0) {
    throw new Error(`Invalid HLC string: ${s}`);
  }
  return {
    p: Number(s.slice(0, i1)),
    c: Number(s.slice(i1 + 1, i2)),
    w: s.slice(i2 + 1),
  };
}

/** 依 p → c → w 比較；回傳 -1 / 0 / 1 */
export function compareHlc(a: Hlc, b: Hlc): number {
  if (a.p !== b.p) return a.p < b.p ? -1 : 1;
  if (a.c !== b.c) return a.c < b.c ? -1 : 1;
  if (a.w !== b.w) return a.w < b.w ? -1 : 1;
  return 0;
}

/** GENERATE：本地寫入事件的下一個時鐘。lastIssued 為 null 視為起點 */
export function generateHlc(lastIssued: Hlc | null, nowMs: number, writerId: string): Hlc {
  const lastP = lastIssued?.p ?? -1;
  const p = Math.max(nowMs, lastP);
  const c = lastIssued !== null && p === lastIssued.p ? lastIssued.c + 1 : 0;
  return { p, c, w: writerId };
}

/** RECEIVE：觀察到遠端時鐘後推進本地 lastIssued (標準 HLC 合併規則) */
export function receiveHlc(
  lastIssued: Hlc | null,
  remote: Hlc,
  nowMs: number,
  writerId: string,
): Hlc {
  const lastP = lastIssued?.p ?? -1;
  const p = Math.max(lastP, remote.p, nowMs);
  const tieLast = lastIssued !== null && p === lastIssued.p;
  const tieRemote = p === remote.p;

  let c: number;
  if (tieLast && tieRemote) {
    c = Math.max(lastIssued!.c, remote.c) + 1;
  } else if (tieLast) {
    c = lastIssued!.c + 1;
  } else if (tieRemote) {
    c = remote.c + 1;
  } else {
    c = 0;
  }
  return { p, c, w: writerId };
}

/** 偏移容忍：incoming 物理時間不得超過 now 容忍界 */
export function isWithinSkewTolerance(
  remoteP: number,
  nowMs: number,
  toleranceMs: number = SKEW_TOLERANCE_MS,
): boolean {
  return remoteP <= nowMs + toleranceMs;
}
