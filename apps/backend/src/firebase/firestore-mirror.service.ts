import { Injectable, Logger } from '@nestjs/common';
import { FirebaseService } from './firebase.service';

// 訂單鏡像資料：至少含 id 與 photos (base64)，其餘欄位原樣帶入 Firestore 文件。
export interface OrderMirrorData {
  id: string;
  photos?: string[];
}

// 鏡像時附帶的同步信封 metadata (每欄位 HLC 等)，寫入文件的 _fieldClocks。
export interface OrderMirrorMeta {
  fieldClocks?: Record<string, string>;
}

// 去除 data URL 前綴 (data:image/...;base64,)，只留 base64 內容。
function stripDataUrl(value: string): string {
  const comma = value.indexOf(',');
  return value.startsWith('data:') && comma >= 0 ? value.slice(comma + 1) : value;
}

// 鏡像涵蓋的 collection (對齊 spec「Mirror covers all mirrored collections」)。
export type MirrorCollection =
  | 'orders'
  | 'campaigns'
  | 'categories'
  | 'orderSources'
  | 'verificationStatuses'
  | 'paymentMethods'
  | 'settings';

// 後端為唯一 Firestore 寫入方 (對齊 spec「Backend is the sole writer of Firestore」)：
// 將領域資料鏡像到 per-user 路徑 users/{uid}/{collection}/{id}。
// Firestore 為非權威投影 (Postgres 為 source of truth)：鏡像失敗不拋出、不影響已成功的
// Postgres 寫入，僅記錄供重試 (對齊 spec「Firestore is non-authoritative」)。
@Injectable()
export class FirestoreMirrorService {
  private readonly logger = new Logger(FirestoreMirrorService.name);

  constructor(private readonly firebase: FirebaseService) {}

  private docPath(uid: string, collection: MirrorCollection, id: string): string {
    return `users/${uid}/${collection}/${id}`;
  }

  // upsert 一筆文件到使用者的 collection；失敗僅記錄、不中斷呼叫者。
  async upsert(
    uid: string,
    collection: MirrorCollection,
    id: string,
    data: object,
  ): Promise<void> {
    try {
      await this.firebase.firestore
        .doc(this.docPath(uid, collection, id))
        .set(data as Record<string, unknown>);
    } catch (err) {
      this.recordFailure('upsert', uid, collection, id, err);
    }
  }

  // 鏡像訂單：照片改存 Firebase Storage、Firestore 文件僅放參照 (對齊 spec
  // 「Mirrored documents stay within the Firestore document size limit」)，避免 base64
  // 內嵌撐爆 Firestore 單文件 1 MiB 上限。
  async mirrorOrder(
    uid: string,
    order: OrderMirrorData,
    meta?: OrderMirrorMeta,
  ): Promise<void> {
    const photoRefs = await this.uploadOrderPhotos(uid, order.id, order.photos ?? []);
    const doc: Record<string, unknown> = { ...order, photos: photoRefs };
    if (meta?.fieldClocks) {
      doc._fieldClocks = meta.fieldClocks;
    }
    await this.upsert(uid, 'orders', order.id, doc);
  }

  // 上傳訂單 base64 照片到 Storage users/{uid}/orders/{id}/photo-{i}.jpg，回傳參照路徑陣列。
  private async uploadOrderPhotos(
    uid: string,
    orderId: string,
    photos: string[],
  ): Promise<string[]> {
    if (photos.length === 0) return [];
    const refs: string[] = [];
    for (let i = 0; i < photos.length; i++) {
      const path = `users/${uid}/orders/${orderId}/photo-${i}.jpg`;
      try {
        const buffer = Buffer.from(stripDataUrl(photos[i]), 'base64');
        await this.firebase.storage
          .bucket()
          .file(path)
          .save(buffer, { contentType: 'image/jpeg', resumable: false });
        refs.push(path);
      } catch (err) {
        // 單張照片上傳失敗不中斷其餘鏡像 (Firestore 非權威)。
        this.recordFailure('upsert', uid, 'orders', `${orderId}#photo-${i}`, err);
      }
    }
    return refs;
  }

  // 刪除使用者 collection 下的一筆文件；失敗僅記錄、不中斷呼叫者。
  async remove(uid: string, collection: MirrorCollection, id: string): Promise<void> {
    try {
      await this.firebase.firestore.doc(this.docPath(uid, collection, id)).delete();
    } catch (err) {
      this.recordFailure('delete', uid, collection, id, err);
    }
  }

  private recordFailure(
    op: 'upsert' | 'delete',
    uid: string,
    collection: MirrorCollection,
    id: string,
    err: unknown,
  ): void {
    // 記錄供重試 (重試佇列的具體形式為 apply 前 open question；此處先記錄告警，主流程不受影響)。
    this.logger.warn(
      `Firestore 鏡像失敗 (${op} users/${uid}/${collection}/${id})：${String(err)}`,
    );
  }
}
