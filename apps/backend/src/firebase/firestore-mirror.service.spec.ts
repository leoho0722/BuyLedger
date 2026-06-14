jest.mock('firebase-admin/app', () => ({
  initializeApp: jest.fn(),
  getApps: jest.fn(() => []),
  cert: jest.fn(),
}));
jest.mock('firebase-admin/auth', () => ({ getAuth: jest.fn() }));
jest.mock('firebase-admin/firestore', () => ({ getFirestore: jest.fn() }));
jest.mock('firebase-admin/storage', () => ({ getStorage: jest.fn() }));

import { FirestoreMirrorService, OrderMirrorData } from './firestore-mirror.service';
import { FirebaseService } from './firebase.service';

describe('FirestoreMirrorService', () => {
  function makeService() {
    const set = jest.fn().mockResolvedValue(undefined);
    const del = jest.fn().mockResolvedValue(undefined);
    const doc = jest.fn(() => ({ set, delete: del }));
    const firebase = { firestore: { doc } } as unknown as FirebaseService;
    const service = new FirestoreMirrorService(firebase);
    return { service, doc, set, del };
  }

  // 對齊 spec「Backend is the sole writer of Firestore」與
  // 「Authoritative writes are mirrored to per-user Firestore collections」。
  it('upserts to the per-user path users/{uid}/{collection}/{id}', async () => {
    const { service, doc, set } = makeService();
    await service.upsert('U1', 'orders', 'ORD1', { id: 'ORD1', foo: 'bar' });
    expect(doc).toHaveBeenCalledWith('users/U1/orders/ORD1');
    expect(set).toHaveBeenCalledWith({ id: 'ORD1', foo: 'bar' });
  });

  it('deletes the corresponding per-user document', async () => {
    const { service, doc, del } = makeService();
    await service.remove('U1', 'campaigns', 'CMP1');
    expect(doc).toHaveBeenCalledWith('users/U1/campaigns/CMP1');
    expect(del).toHaveBeenCalled();
  });

  // 對齊 spec「Mirror covers all mirrored collections」。
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

  // 對齊 spec「Firestore is non-authoritative」：鏡像失敗不得拋出、不影響呼叫者。
  it('does not throw when the Firestore write fails', async () => {
    const set = jest.fn().mockRejectedValue(new Error('firestore down'));
    const doc = jest.fn(() => ({ set, delete: jest.fn() }));
    const firebase = { firestore: { doc } } as unknown as FirebaseService;
    const service = new FirestoreMirrorService(firebase);
    await expect(service.upsert('U1', 'orders', 'ORD1', {})).resolves.toBeUndefined();
  });

  // 對齊 spec「Mirrored documents stay within the Firestore document size limit」。
  it('uploads order photos to Storage and stores only references in Firestore', async () => {
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
      photos: ['data:image/jpeg;base64,QUJD', 'WFla'],
      chargedAmount: '100',
    } as OrderMirrorData);

    expect(file).toHaveBeenCalledWith('users/U1/orders/ORD1/photo-0.jpg');
    expect(file).toHaveBeenCalledWith('users/U1/orders/ORD1/photo-1.jpg');
    expect(save).toHaveBeenCalledTimes(2);
    const written = set.mock.calls[0][0] as { photos: string[] };
    expect(written.photos).toEqual([
      'users/U1/orders/ORD1/photo-0.jpg',
      'users/U1/orders/ORD1/photo-1.jpg',
    ]);
    // Firestore 文件不得含 raw base64 內容。
    expect(JSON.stringify(written)).not.toContain('QUJD');
  });
});
