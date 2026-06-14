// firebase-admin v14 依賴 ESM-only 的 jose，jest (CJS) 直接載入會失敗；單元測試一律
// mock firebase-admin 子模組，避免載入真 SDK，也確保不對外建立連線。
jest.mock('firebase-admin/app', () => ({
  initializeApp: jest.fn(),
  getApps: jest.fn(() => []),
  cert: jest.fn(),
}));
jest.mock('firebase-admin/auth', () => ({ getAuth: jest.fn() }));
jest.mock('firebase-admin/firestore', () => ({ getFirestore: jest.fn() }));
jest.mock('firebase-admin/storage', () => ({ getStorage: jest.fn() }));

import { cert, initializeApp } from 'firebase-admin/app';
import { FirebaseService } from './firebase.service';

// 對齊 spec「Missing Firebase credentials fail closed」：初始化時缺憑證一律拋錯，
// 不得靜默略過初始化讓後端在未驗證狀態下啟動。
describe('FirebaseService fail-closed initialization', () => {
  const savedEnv = { ...process.env };

  afterEach(() => {
    process.env = { ...savedEnv };
    jest.clearAllMocks();
  });

  it('throws on init when neither a credential file nor env vars are present', () => {
    delete process.env.FIREBASE_SERVICE_ACCOUNT_FILE;
    delete process.env.FIREBASE_PROJECT_ID;
    delete process.env.FIREBASE_CLIENT_EMAIL;
    delete process.env.FIREBASE_PRIVATE_KEY;

    const service = new FirebaseService();
    expect(() => service.onModuleInit()).toThrow(/FIREBASE_/);
    // fail closed：缺憑證時絕不進行初始化。
    expect(initializeApp).not.toHaveBeenCalled();
  });

  it('initializes the admin app once from individual env credentials', () => {
    delete process.env.FIREBASE_SERVICE_ACCOUNT_FILE;
    process.env.FIREBASE_PROJECT_ID = 'demo-project';
    process.env.FIREBASE_CLIENT_EMAIL = 'svc@demo-project.iam.gserviceaccount.com';
    process.env.FIREBASE_PRIVATE_KEY = '-----BEGIN PRIVATE KEY-----\\nABC\\n-----END PRIVATE KEY-----\\n';

    const service = new FirebaseService();
    service.onModuleInit();
    expect(initializeApp).toHaveBeenCalledTimes(1);
  });

  it('prefers a service account file when FIREBASE_SERVICE_ACCOUNT_FILE is set', () => {
    process.env.FIREBASE_SERVICE_ACCOUNT_FILE = '/secrets/sa.json';
    delete process.env.FIREBASE_PROJECT_ID;
    delete process.env.FIREBASE_CLIENT_EMAIL;
    delete process.env.FIREBASE_PRIVATE_KEY;

    const service = new FirebaseService();
    service.onModuleInit();
    // 以檔案路徑作為憑證來源 (不需三個分開的 env 變數)。
    expect(cert).toHaveBeenCalledWith('/secrets/sa.json');
    expect(initializeApp).toHaveBeenCalledTimes(1);
  });
});
