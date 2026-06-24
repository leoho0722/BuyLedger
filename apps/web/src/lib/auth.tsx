'use client';

import {
  GoogleAuthProvider,
  OAuthProvider,
  onAuthStateChanged,
  signInWithPopup,
  signInWithCustomToken,
  signOut as firebaseSignOut,
  type User,
} from 'firebase/auth';
import { useRouter } from 'next/navigation';
import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import { getFirebaseAuth } from './firebase';
import { setUnauthorizedHandler } from './api';

interface AuthState {
  user: User | null;
  loading: boolean;
  signInWithGoogle: () => Promise<void>;
  signInWithApple: () => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthState | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
    const auth = getFirebaseAuth();
    const unsubscribe = onAuthStateChanged(auth, (next) => {
      setUser(next);
      setLoading(false);
    });
    // API 收到 401 時登出，AuthGate 隨即導回登入
    setUnauthorizedHandler(() => {
      void firebaseSignOut(getFirebaseAuth());
    });
    // Dev-only 自動登入掛鉤：以後端 dev custom token 換 ID token，繞過互動式 OAuth
    // (CDP 控制的瀏覽器無法完成 Google/Apple 登入)。安全邊界在後端：DEV_AUTH_ENABLED
    // 未開時 /dev/token 回 404、此掛鉤即無效。瀏覽器 console 可呼叫 window.__devSignIn('uid')
    (window as unknown as { __devSignIn?: (uid?: string) => Promise<void> }).__devSignIn = async (
      uid = 'demo-user',
    ) => {
      const base = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000/api';
      const res = await fetch(`${base}/dev/token`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ uid }),
      });
      if (!res.ok) throw new Error(`dev token 取得失敗 (${res.status})`);
      const { token } = (await res.json()) as { token: string };
      await signInWithCustomToken(getFirebaseAuth(), token);
    };
    return unsubscribe;
  }, []);

  const signInWithGoogle = async (): Promise<void> => {
    await signInWithPopup(getFirebaseAuth(), new GoogleAuthProvider());
  };

  const signInWithApple = async (): Promise<void> => {
    await signInWithPopup(getFirebaseAuth(), new OAuthProvider('apple.com'));
  };

  const signOut = async (): Promise<void> => {
    await firebaseSignOut(getFirebaseAuth());
    // 登出後導回首頁，再登入時落在總覽 (而非原本的設定頁)
    router.replace('/');
  };

  return (
    <AuthContext.Provider value={{ user, loading, signInWithGoogle, signInWithApple, signOut }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthState {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth 必須在 AuthProvider 內使用');
  return context;
}

// 未登入時顯示登入畫面、登入後才放行 App 內容
export function AuthGate({ children }: { children: ReactNode }) {
  const { user, loading } = useAuth();
  if (loading) {
    return (
      <div className="flex min-h-dvh items-center justify-center text-bl-secondary-label">載入中…</div>
    );
  }
  if (!user) return <SignIn />;
  return <>{children}</>;
}

function SignIn() {
  const { signInWithGoogle, signInWithApple } = useAuth();
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const run = async (fn: () => Promise<void>): Promise<void> => {
    setError(null);
    setBusy(true);
    try {
      await fn();
    } catch {
      setError('登入失敗，請再試一次');
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="flex min-h-dvh items-center justify-center bg-bl-background px-6">
      <div className="bl-card-shadow w-full max-w-sm rounded-bl-lg border border-bl-separator bg-bl-surface p-8">
        <h1 className="text-center text-xl font-semibold text-bl-label">BuyLedger</h1>
        <p className="mt-1 text-center text-sm text-bl-secondary-label">登入以管理你的代購記帳</p>

        <div className="mt-8 space-y-3">
          <button
            type="button"
            disabled={busy}
            onClick={() => void run(signInWithGoogle)}
            className="w-full rounded-bl-md border border-bl-separator bg-bl-surface py-3 text-sm font-medium text-bl-label transition hover:bg-bl-fill disabled:opacity-50"
          >
            以 Google 登入
          </button>
          <button
            type="button"
            disabled={busy}
            onClick={() => void run(signInWithApple)}
            className="w-full rounded-bl-md bg-bl-label py-3 text-sm font-medium text-bl-background transition hover:opacity-90 disabled:opacity-50"
          >
            以 Apple 登入
          </button>
        </div>

        {error && <p className="mt-4 text-center text-sm text-bl-red">{error}</p>}
      </div>
    </div>
  );
}
