import { Injectable, Logger } from '@nestjs/common';
import { createHash } from 'node:crypto';
import { FirebaseService } from './firebase.service';

// 訂單鏡像資料：至少含 id 與 photos (base64)，其餘欄位原樣帶入 Firestore 文件
export interface OrderMirrorData {
  id: string;
  photos?: string[];
}

// 同步信封 metadata：投影以 _fieldClocks / _writerId 承載
export interface OrderMirrorMeta {
  fieldClocks?: Record<string, string>;
  writerId?: string;
}

// 內聯重試退避 (毫秒)：3 次 100/300/900ms
const RETRY_BACKOFF_MS = [100, 300, 900];

// 去除 data URL 前綴 (data:image/...;base64,)，只留 base64 內容
function stripDataUrl(value: string): string {
  const comma = value.indexOf(',');
  return value.startsWith('data:') && comma >= 0 ? value.slice(comma + 1) : value;
}

// 鏡像涵蓋的 collection
export type MirrorCollection =
  | 'orders'
  | 'campaigns'
  | 'categories'
  | 'orderSources'
  | 'verificationStatuses'
  | 'paymentMethods'
  | 'settings';

// 後端為唯一 Firestore 寫入方，鏡像領域資料到 users/{uid}/{collection}/{id}
// Firestore 非權威 (Postgres 為 SoT)：鏡像失敗不拋、不回退 Postgres 寫入，
// 耗盡重試後回報失敗交呼叫端蓋 mirrorDirty 由背景掃描修復
@Injectable()
export class FirestoreMirrorService {
  private readonly logger = new Logger(FirestoreMirrorService.name);

  constructor(private readonly firebase: FirebaseService) {}

  private docPath(uid: string, collection: MirrorCollection, id: string): string {
    return `users/${uid}/${collection}/${id}`;
  }

  // 有限次內聯重試：成功回 true，耗盡回 false (不拋) 交呼叫端蓋 mirrorDirty
  private async withRetry(
    op: 'upsert' | 'delete',
    uid: string,
    collection: MirrorCollection,
    id: string,
    action: () => Promise<void>,
  ): Promise<boolean> {
    let lastErr: unknown;
    for (let attempt = 0; attempt <= RETRY_BACKOFF_MS.length; attempt++) {
      try {
        await action();
        return true;
      } catch (err) {
        lastErr = err;
        const backoff = RETRY_BACKOFF_MS[attempt];
        if (backoff !== undefined) {
          await delay(backoff);
        }
      }
    }
    this.recordFailure(op, uid, collection, id, lastErr);
    return false;
  }

  // upsert 一筆文件到使用者的 collection；最終失敗僅記錄、不中斷呼叫者，回傳是否成功
  async upsert(
    uid: string,
    collection: MirrorCollection,
    id: string,
    data: object,
  ): Promise<boolean> {
    return this.withRetry('upsert', uid, collection, id, async () => {
      await this.firebase.firestore
        .doc(this.docPath(uid, collection, id))
        .set(data as Record<string, unknown>);
    });
  }

  // 鏡像訂單：照片改存 Storage、文件僅放 photoRefs，避免 base64 撐爆單文件 1 MiB 上限
  async mirrorOrder(
    uid: string,
    order: OrderMirrorData,
    meta?: OrderMirrorMeta,
  ): Promise<boolean> {
    const photoRefs = await this.uploadOrderPhotos(uid, order.id, order.photos ?? []);
    // 剝除 photos 改放 photoRefs；summary 保留供 web 直接呈現
    const { photos: _omitPhotos, ...rest } = order as unknown as Record<string, unknown>;
    const doc: Record<string, unknown> = {
      ...rest,
      photoRefs,
      _deleted: false,
    };
    if (meta?.fieldClocks) {
      doc._fieldClocks = meta.fieldClocks;
    }
    if (meta?.writerId) {
      doc._writerId = meta.writerId;
    }
    return this.upsert(uid, 'orders', order.id, doc);
  }

  // 鏡像訂單 tombstone：以顯式 { _deleted:true, _deleteClock } 表示刪除，絕不用文件缺席
  // 保留 photoRefs/欄位時鐘等信封，供拉取端在保留窗內以時鐘判斷復活
  async mirrorOrderTombstone(
    uid: string,
    order: OrderMirrorData,
    deleteClock: string,
    meta?: OrderMirrorMeta,
  ): Promise<boolean> {
    const photoRefs = await this.uploadOrderPhotos(uid, order.id, order.photos ?? []);
    // 同 mirrorOrder：photos 改 photoRefs、summary 保留
    const { photos: _omitPhotos, ...rest } = order as unknown as Record<string, unknown>;
    const doc: Record<string, unknown> = {
      ...rest,
      photoRefs,
      _deleted: true,
      _deleteClock: deleteClock,
    };
    if (meta?.fieldClocks) {
      doc._fieldClocks = meta.fieldClocks;
    }
    if (meta?.writerId) {
      doc._writerId = meta.writerId;
    }
    return this.upsert(uid, 'orders', order.id, doc);
  }

  // 鏡像一般 collection 的 tombstone：帶 recordClock 或 deleteClock 的顯式刪除標記，取代硬刪
  async mirrorTombstone(
    uid: string,
    collection: MirrorCollection,
    id: string,
    clock: { recordClock?: string; deleteClock?: string },
  ): Promise<boolean> {
    const doc: Record<string, unknown> = { _deleted: true };
    if (clock.recordClock !== undefined) doc.recordClock = clock.recordClock;
    if (clock.deleteClock !== undefined) doc._deleteClock = clock.deleteClock;
    return this.upsert(uid, collection, id, doc);
  }

  // 上傳訂單照片到 Storage，鍵採內容定址 photo-{sha256}.jpg 使重送/重排冪等；
  // 回傳去重後的參照陣列
  private async uploadOrderPhotos(
    uid: string,
    orderId: string,
    photos: string[],
  ): Promise<string[]> {
    if (photos.length === 0) return [];
    const refs: string[] = [];
    const seen = new Set<string>();
    for (let i = 0; i < photos.length; i++) {
      const base64 = stripDataUrl(photos[i]);
      const buffer = Buffer.from(base64, 'base64');
      const sha = createHash('sha256').update(buffer).digest('hex');
      const path = `users/${uid}/orders/${orderId}/photo-${sha}.jpg`;
      if (seen.has(path)) continue;
      seen.add(path);
      try {
        await this.firebase.storage
          .bucket()
          .file(path)
          .save(buffer, { contentType: 'image/jpeg', resumable: false });
        refs.push(path);
      } catch (err) {
        // 單張照片上傳失敗不中斷其餘鏡像 (Firestore 非權威)
        this.recordFailure('upsert', uid, 'orders', `${orderId}#${sha}`, err);
      }
    }
    return refs;
  }

  // 刪除使用者 collection 下的一筆文件；最終失敗僅記錄、不中斷呼叫者，回傳是否成功
  async remove(uid: string, collection: MirrorCollection, id: string): Promise<boolean> {
    return this.withRetry('delete', uid, collection, id, async () => {
      await this.firebase.firestore.doc(this.docPath(uid, collection, id)).delete();
    });
  }

  private recordFailure(
    op: 'upsert' | 'delete',
    uid: string,
    collection: MirrorCollection,
    id: string,
    err: unknown,
  ): void {
    // 內聯重試耗盡後記錄告警；
    // 殘餘缺口由 mirrorDirty 背景掃描 (MirrorSweepService) 自我修復
    this.logger.warn(
      `Firestore 鏡像失敗 (${op} users/${uid}/${collection}/${id})：${String(err)}`,
    );
  }
}

// 退避等待 (測試以 fake timers 或直接呼叫掃描方法繞過)
function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
