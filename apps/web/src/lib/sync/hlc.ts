// 跨裝置同步的 Hybrid Logical Clock (HLC) — web 端實作，與後端 apps/backend/src/sync/hlc.ts
// 演算法完全一致 (規格與 conformance vectors 見 shared/sync-conformance/)
// writerId 採每安裝穩定 UUID (存 localStorage)；若日後改用 FCM device token，只需替換
// getWriterId() 的來源 (見 design 決策 ②)。實體時間集中在本檔的 now() 單一呼叫點

/** 單一 HLC 時間戳：物理時間 + 邏輯計數器 + 寫入者，三者依序決定全序 */
export interface Hlc {
  /** 物理毫秒 (epoch millis) */
  p: number;
  /** 邏輯計數器 (同一毫秒內的因果序) */
  c: number;
  /** 寫入者識別 (決勝最後一關) */
  w: string;
}

// 編碼時 p / c 各自左補零的固定寬度，確保字串可按字典序排序 (須與後端一致)
const P_WIDTH = 13;
const C_WIDTH = 6;

/** 未來時鐘容忍度 (毫秒)；與後端一致 */
export const SKEW_TOLERANCE_MS = 5 * 60 * 1000;

/** 左補零至指定寬度，供 encodeHlc 產生可排序字串 */
function pad(value: number, width: number): string {
  const s = String(value);
  return s.length >= width ? s : '0'.repeat(width - s.length) + s;
}

/** 序列化為可排序字串 `p(13):c(6):w` */
export function encodeHlc(h: Hlc): string {
  return `${pad(h.p, P_WIDTH)}:${pad(h.c, C_WIDTH)}:${h.w}`;
}

/** 反序列化 `p:c:w` */
export function decodeHlc(s: string): Hlc {
  const i1 = s.indexOf(':');
  const i2 = s.indexOf(':', i1 + 1);
  if (i1 < 0 || i2 < 0) throw new Error(`Invalid HLC string: ${s}`);
  return { p: Number(s.slice(0, i1)), c: Number(s.slice(i1 + 1, i2)), w: s.slice(i2 + 1) };
}

/** 依 p → c → w 比較；回傳 -1 / 0 / 1 */
export function compareHlc(a: Hlc, b: Hlc): number {
  if (a.p !== b.p) return a.p < b.p ? -1 : 1;
  if (a.c !== b.c) return a.c < b.c ? -1 : 1;
  if (a.w !== b.w) return a.w < b.w ? -1 : 1;
  return 0;
}

/** GENERATE：本地寫入事件的下一個時鐘 */
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
  if (tieLast && tieRemote) c = Math.max(lastIssued!.c, remote.c) + 1;
  else if (tieLast) c = lastIssued!.c + 1;
  else if (tieRemote) c = remote.c + 1;
  else c = 0;
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

// ----- 本地時鐘狀態 (writerId 與 lastIssued 持久化於 localStorage，跨 reload 存活) -----

const WRITER_KEY = 'buyledger.sync.writerId';
const LAST_KEY = 'buyledger.sync.lastIssuedHlc';

/** 單一系統時間呼叫點 (對齊環境相依注入精神；測試可傳入 nowMs) */
function now(): number {
  return Date.now();
}

/** 每安裝穩定 writerId (localStorage)；SSR 期回固定占位值、不寫入 */
export function getWriterId(): string {
  if (typeof window === 'undefined') return 'web-ssr';
  let id = window.localStorage.getItem(WRITER_KEY);
  if (!id) {
    id = window.crypto.randomUUID();
    window.localStorage.setItem(WRITER_KEY, id);
  }
  return id;
}

/** 讀回上次發出的 lastIssued (SSR 或解析失敗時視為無) */
function loadLast(): Hlc | null {
  if (typeof window === 'undefined') return null;
  const raw = window.localStorage.getItem(LAST_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as Hlc;
  } catch {
    return null;
  }
}

/** 持久化 lastIssued 以跨 reload 維持時鐘單調遞增 */
function saveLast(h: Hlc): void {
  if (typeof window === 'undefined') return;
  window.localStorage.setItem(LAST_KEY, JSON.stringify(h));
}

/** 產生下一個本地時鐘 (編碼字串)，並持久化 lastIssued */
export function nextClock(nowMs: number = now()): string {
  const next = generateHlc(loadLast(), nowMs, getWriterId());
  saveLast(next);
  return encodeHlc(next);
}

/** 觀察到遠端時鐘 (拉回欄位/文件) 後推進本地 lastIssued，使後續本地寫入時鐘必大於它 */
export function observeClock(remoteEnc: string, nowMs: number = now()): void {
  let remote: Hlc;
  try {
    remote = decodeHlc(remoteEnc);
  } catch {
    return;
  }
  saveLast(receiveHlc(loadLast(), remote, nowMs, getWriterId()));
}
