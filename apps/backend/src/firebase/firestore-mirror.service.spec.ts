jest.mock('firebase-admin/app', () => ({
  initializeApp: jest.fn(),
  getApps: jest.fn(() => []),
  cert: jest.fn(),
}));
jest.mock('firebase-admin/auth', () => ({ getAuth: jest.fn() }));
jest.mock('firebase-admin/firestore', () => ({ getFirestore: jest.fn() }));
jest.mock('firebase-admin/storage', () => ({ getStorage: jest.fn() }));

import { createHash } from 'node:crypto';
import { FirestoreMirrorService, OrderMirrorData } from './firestore-mirror.service';
import { FirebaseService } from './firebase.service';

// 內容定址鍵：
// 與 service 內 uploadOrderPhotos 的雜湊演算法對齊 (sha256 of decoded bytes)
function photoKey(uid: string, orderId: string, base64: string): string {
  const sha = createHash('sha256').update(Buffer.from(base64, 'base64')).digest('hex');
  return `users/${uid}/orders/${orderId}/photo-${sha}.jpg`;
}

describe('FirestoreMirrorService', () => {
  function makeService() {
    const set = jest.fn().mockResolvedValue(undefined);
    const del = jest.fn().mockResolvedValue(undefined);
    const doc = jest.fn(() => ({ set, delete: del }));
    const firebase = { firestore: { doc } } as unknown as FirebaseService;
    const service = new FirestoreMirrorService(firebase);
    return { service, doc, set, del };
  }

  // 後端為唯一寫入方，權威寫入鏡像到 per-user Firestore
  it('upserts to the per-user path users/{uid}/{collection}/{id}', async () => {
    const { service, doc, set } = makeService();
    const ok = await service.upsert('U1', 'orders', 'ORD1', { id: 'ORD1', foo: 'bar' });
    expect(ok).toBe(true);
    expect(doc).toHaveBeenCalledWith('users/U1/orders/ORD1');
    expect(set).toHaveBeenCalledWith({ id: 'ORD1', foo: 'bar' });
  });

  it('deletes the corresponding per-user document', async () => {
    const { service, doc, del } = makeService();
    await service.remove('U1', 'campaigns', 'CMP1');
    expect(doc).toHaveBeenCalledWith('users/U1/campaigns/CMP1');
    expect(del).toHaveBeenCalled();
  });

  // 鏡像涵蓋所有受支援的 collection
  it('mirrors every supported collection under the user path', async () => {
    const { service, doc } = makeService();
    const collections = [
      'orders',
      'campaigns',
      'categories',
      'orderSources',
      'verificationStatuses',
      'paymentMethods',
      'settings',
    ] as const;
    for (const c of collections) {
      await service.upsert('U1', c, 'X', {});
    }
    for (const c of collections) {
      expect(doc).toHaveBeenCalledWith(`users/U1/${c}/X`);
    }
  });

  // Firestore 非權威：鏡像最終失敗不拋出、不影響呼叫者，回 false
  it('does not throw when the Firestore write fails, returns false after exhausting retries', async () => {
    const set = jest.fn().mockRejectedValue(new Error('firestore down'));
    const doc = jest.fn(() => ({ set, delete: jest.fn() }));
    const firebase = { firestore: { doc } } as unknown as FirebaseService;
    const service = new FirestoreMirrorService(firebase);
    const ok = await service.upsert('U1', 'orders', 'ORD1', {});
    expect(ok).toBe(false);
    // 1 初試 + 3 重試 = 4 次
    expect(set).toHaveBeenCalledTimes(4);
  });

  // 瞬時失敗重試成功則回 true、不蓋 dirty
  it('retries inline and succeeds when a transient failure recovers', async () => {
    const set = jest
      .fn()
      .mockRejectedValueOnce(new Error('transient'))
      .mockResolvedValueOnce(undefined);
    const doc = jest.fn(() => ({ set, delete: jest.fn() }));
    const firebase = { firestore: { doc } } as unknown as FirebaseService;
    const service = new FirestoreMirrorService(firebase);
    const ok = await service.upsert('U1', 'orders', 'ORD1', {});
    expect(ok).toBe(true);
    expect(set).toHaveBeenCalledTimes(2);
  });

  // 照片存 Storage、文件只放 photoRefs，避免超過 Firestore 單文件大小上限
  it('uploads order photos to content-addressed Storage keys and stores only photoRefs', async () => {
    const save = jest.fn().mockResolvedValue(undefined);
    const file = jest.fn(() => ({ save }));
    const bucket = jest.fn(() => ({ file }));
    const set = jest.fn().mockResolvedValue(undefined);
    const doc = jest.fn(() => ({ set, delete: jest.fn() }));
    const firebase = {
      firestore: { doc },
      storage: { bucket },
    } as unknown as FirebaseService;
    const service = new FirestoreMirrorService(firebase);

    const p0 = 'QUJD';
    const p1 = 'WFla';
    // 帶 summary 的真實 OrderDTO 形狀：
    // 斷言 summary 隨投影保留 (供 web 直接呈現)
    await service.mirrorOrder('U1', {
      id: 'ORD1',
      photos: [`data:image/jpeg;base64,${p0}`, p1],
      chargedAmount: '100',
      summary: { revenue: '100', cost: '0', profit: '100', margin: '1', platformFee: '0' },
    } as unknown as OrderMirrorData);

    const k0 = photoKey('U1', 'ORD1', p0);
    const k1 = photoKey('U1', 'ORD1', p1);
    expect(file).toHaveBeenCalledWith(k0);
    expect(file).toHaveBeenCalledWith(k1);
    expect(save).toHaveBeenCalledTimes(2);
    const written = set.mock.calls[0][0] as Record<string, unknown>;
    expect(written.photoRefs).toEqual([k0, k1]);
    // 投影信封：未刪除帶 _deleted=false、含 summary、不含 photos / base64
    expect(written._deleted).toBe(false);
    expect(written.photos).toBeUndefined();
    expect(written.summary).toEqual({ revenue: '100', cost: '0', profit: '100', margin: '1', platformFee: '0' });
    expect(JSON.stringify(written)).not.toContain('QUJD');
  });

  // 同一張照片重送/重排只上傳一次、photoRefs 去重 (內容定址冪等)
  it('dedupes identical photo content to a single content-addressed ref', async () => {
    const save = jest.fn().mockResolvedValue(undefined);
    const file = jest.fn(() => ({ save }));
    const bucket = jest.fn(() => ({ file }));
    const set = jest.fn().mockResolvedValue(undefined);
    const doc = jest.fn(() => ({ set, delete: jest.fn() }));
    const firebase = {
      firestore: { doc },
      storage: { bucket },
    } as unknown as FirebaseService;
    const service = new FirestoreMirrorService(firebase);

    await service.mirrorOrder('U1', {
      id: 'ORD1',
      photos: ['QUJD', 'QUJD'],
    } as OrderMirrorData);

    const written = set.mock.calls[0][0] as Record<string, unknown>;
    expect((written.photoRefs as string[]).length).toBe(1);
    expect(save).toHaveBeenCalledTimes(1);
  });

  // 刪除為顯式 tombstone 文件、非以缺席表示
  it('mirrors an order tombstone as an explicit deleted document with envelope keys', async () => {
    const save = jest.fn().mockResolvedValue(undefined);
    const file = jest.fn(() => ({ save }));
    const bucket = jest.fn(() => ({ file }));
    const set = jest.fn().mockResolvedValue(undefined);
    const doc = jest.fn(() => ({ set, delete: jest.fn() }));
    const firebase = {
      firestore: { doc },
      storage: { bucket },
    } as unknown as FirebaseService;
    const service = new FirestoreMirrorService(firebase);

    const deleteClock = '0000001700000:000000:server';
    await service.mirrorOrderTombstone(
      'U1',
      { id: 'ORD1', photos: [] } as OrderMirrorData,
      deleteClock,
      { fieldClocks: { customerName: '0000001000000:000000:device-a' }, writerId: 'server' },
    );
    const written = set.mock.calls[0][0] as Record<string, unknown>;
    expect(written._deleted).toBe(true);
    expect(written._deleteClock).toBe(deleteClock);
    expect(written._fieldClocks).toEqual({ customerName: '0000001000000:000000:device-a' });
    expect(written._writerId).toBe('server');
  });

  // lookup / campaign tombstone：
  // 帶 recordClock 或 deleteClock 的顯式刪除文件
  it('mirrors a lookup tombstone with recordClock', async () => {
    const { service, set } = makeService();
    await service.mirrorTombstone('U1', 'categories', '美妝', { recordClock: 'rc-1' });
    expect(set).toHaveBeenCalledWith({ _deleted: true, recordClock: 'rc-1' });
  });
});
