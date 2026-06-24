import { getApp, getApps, initializeApp, type FirebaseApp } from 'firebase/app';
import { getAuth, type Auth } from 'firebase/auth';
import { getFirestore, type Firestore } from 'firebase/firestore';

// Firebase web 設定由 NEXT_PUBLIC_FIREBASE_* 於 build 期 inline (對齊 web CLAUDE.md 的
// NEXT_PUBLIC_* 慣例)；實際值見 .env.local，不寫死於程式碼
const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
  measurementId: process.env.NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID,
};

// 延遲初始化：避免於 SSR/prerender 期 (build 時無 NEXT_PUBLIC_* 值) 觸發 getAuth 的
// apiKey 驗證而中斷靜態產生。只有在瀏覽器端實際使用時才初始化
let cachedAuth: Auth | null = null;

export function getFirebaseAuth(): Auth {
  if (!cachedAuth) {
    const app: FirebaseApp = getApps().length ? getApp() : initializeApp(firebaseConfig);
    cachedAuth = getAuth(app);
  }
  return cachedAuth;
}

// Firestore 即時投影的讀取進入點 (後端為唯一寫入方；web 僅 onSnapshot 讀取)。延遲初始化
let cachedDb: Firestore | null = null;

export function getFirestoreDb(): Firestore {
  if (!cachedDb) {
    const app: FirebaseApp = getApps().length ? getApp() : initializeApp(firebaseConfig);
    cachedDb = getFirestore(app);
  }
  return cachedDb;
}

// 取得目前使用者的 Firebase ID token (供 API client 夾帶 Authorization)；SSR 或未登入回 null
export async function getCurrentIdToken(): Promise<string | null> {
  if (typeof window === 'undefined') return null;
  const user = getFirebaseAuth().currentUser;
  return user ? user.getIdToken() : null;
}
