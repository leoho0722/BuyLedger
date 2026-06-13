import type { Metadata } from 'next';
import './globals.css';
import { Providers } from '@/lib/providers';
import { AppShell } from '@/components/AppShell';

export const metadata: Metadata = {
  title: 'BuyLedger',
  description: '個人代購記帳與開團管理',
};

// 在繪製前依偏好套用深色，避免閃爍。
const antiFlash = `(function(){try{var a=localStorage.getItem('bl-appearance')||'system';var d=a==='dark'||(a==='system'&&window.matchMedia('(prefers-color-scheme: dark)').matches);if(d)document.documentElement.classList.add('dark');}catch(e){}})();`;

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="zh-Hant" suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: antiFlash }} />
      </head>
      <body>
        <Providers>
          <AppShell>{children}</AppShell>
        </Providers>
      </body>
    </html>
  );
}
