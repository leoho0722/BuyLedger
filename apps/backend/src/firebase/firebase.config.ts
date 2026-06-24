// Firebase service account 憑證解析。對齊 spec「Missing Firebase credentials fail closed」：
// 缺任一必要憑證一律拋錯 (fail closed)，不得回傳部分憑證讓服務在未驗證狀態下啟動
// 憑證值 (尤其 private key) 不寫入 log

export interface FirebaseCredentials {
  readonly projectId: string;
  readonly clientEmail: string;
  readonly privateKey: string;
}

// 必填環境變數名稱；缺任一即視為未設定憑證
const REQUIRED_KEYS = [
  'FIREBASE_PROJECT_ID',
  'FIREBASE_CLIENT_EMAIL',
  'FIREBASE_PRIVATE_KEY',
] as const;

function requireEnv(env: NodeJS.ProcessEnv, key: string): string {
  const value = env[key];
  if (typeof value !== 'string' || value.trim() === '') {
    // 僅指出缺哪個變數，不輸出其值
    throw new Error(
      `缺少 Firebase service account 憑證環境變數 ${key}；後端拒絕在無憑證下啟動 (fail closed)。`,
    );
  }
  return value;
}

export function resolveFirebaseCredentials(env: NodeJS.ProcessEnv): FirebaseCredentials {
  const [projectId, clientEmail, rawPrivateKey] = REQUIRED_KEYS.map((key) =>
    requireEnv(env, key),
  );

  return {
    projectId,
    clientEmail,
    // 環境變數常以字面 \n 儲存多行 private key，cert() 需要真正換行，否則解析失敗
    privateKey: rawPrivateKey.replace(/\\n/g, '\n'),
  };
}

// 憑證來源：service account JSON 檔路徑，或三個分開的環境變數構成的 inline 憑證
export type FirebaseCredentialSource =
  | { readonly kind: 'file'; readonly path: string }
  | { readonly kind: 'inline'; readonly credentials: FirebaseCredentials };

/// 解析 Firebase 憑證來源：優先用 service account JSON 檔 (`FIREBASE_SERVICE_ACCOUNT_FILE`)，
/// 否則回退到三個分開的環境變數；兩者皆無則 fail closed (拋錯)
export function resolveFirebaseCredentialSource(env: NodeJS.ProcessEnv): FirebaseCredentialSource {
  const file = env.FIREBASE_SERVICE_ACCOUNT_FILE;
  if (typeof file === 'string' && file.trim() !== '') {
    return { kind: 'file', path: file.trim() };
  }
  return { kind: 'inline', credentials: resolveFirebaseCredentials(env) };
}
