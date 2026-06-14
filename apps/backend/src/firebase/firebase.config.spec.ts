import { resolveFirebaseCredentials } from './firebase.config';

// 對齊 spec「Missing Firebase credentials fail closed」：缺任一必要憑證一律拋錯，
// 不得回傳部分／預設憑證讓服務在未驗證狀態下啟動。
describe('resolveFirebaseCredentials', () => {
  const fullEnv = {
    FIREBASE_PROJECT_ID: 'demo-project',
    FIREBASE_CLIENT_EMAIL: 'svc@demo-project.iam.gserviceaccount.com',
    FIREBASE_PRIVATE_KEY: '-----BEGIN PRIVATE KEY-----\\nLINE1\\nLINE2\\n-----END PRIVATE KEY-----\\n',
  };

  it('throws when FIREBASE_PROJECT_ID is missing', () => {
    const env = { ...fullEnv, FIREBASE_PROJECT_ID: undefined };
    expect(() => resolveFirebaseCredentials(env)).toThrow(/FIREBASE_PROJECT_ID/);
  });

  it('throws when FIREBASE_CLIENT_EMAIL is missing', () => {
    const env = { ...fullEnv, FIREBASE_CLIENT_EMAIL: '' };
    expect(() => resolveFirebaseCredentials(env)).toThrow(/FIREBASE_CLIENT_EMAIL/);
  });

  it('throws when FIREBASE_PRIVATE_KEY is missing', () => {
    const env = { ...fullEnv, FIREBASE_PRIVATE_KEY: undefined };
    expect(() => resolveFirebaseCredentials(env)).toThrow(/FIREBASE_PRIVATE_KEY/);
  });

  it('returns credentials and normalizes escaped newlines in the private key', () => {
    const creds = resolveFirebaseCredentials(fullEnv);
    expect(creds.projectId).toBe('demo-project');
    expect(creds.clientEmail).toBe('svc@demo-project.iam.gserviceaccount.com');
    // 環境變數中的字面 \n 必須還原為真正換行，否則 cert() 會解析失敗。
    expect(creds.privateKey).toContain('\n');
    expect(creds.privateKey).not.toContain('\\n');
  });
});
