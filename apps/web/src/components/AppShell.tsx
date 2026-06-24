'use client';

import { BarChart3, House, Menu, Package, ReceiptText, X } from 'lucide-react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useEffect, useState } from 'react';
import { cn } from '@/lib/cn';
import { ACTIVE_STATUSES } from '@/lib/domain/constants';
import { useOrders } from '@/lib/queries';
import { BLCountBadge } from './ds/BLBadge';

const NAV = [
  { href: '/', label: '總覽', icon: House, key: 'dashboard' },
  { href: '/orders', label: '訂單', icon: ReceiptText, key: 'orders' },
  { href: '/campaigns', label: '開團', icon: Package, key: 'campaigns' },
  { href: '/insights', label: '分析', icon: BarChart3, key: 'insights' },
  { href: '/more', label: '更多', icon: Menu, key: 'more' },
] as const;

function activeKey(pathname: string): string {
  if (pathname === '/') return 'dashboard';
  if (pathname.startsWith('/orders')) return 'orders';
  if (pathname.startsWith('/campaigns')) return 'campaigns';
  if (pathname.startsWith('/insights')) return 'insights';
  return 'more';
}

export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const active = activeKey(pathname);
  const { data: orders } = useOrders();
  const activeCount = (orders ?? []).filter((o) => ACTIVE_STATUSES.has(o.status)).length;
  const [drawerOpen, setDrawerOpen] = useState(false);

  // 路由變更時自動收起手機抽屜
  useEffect(() => {
    setDrawerOpen(false);
  }, [pathname]);

  // 抽屜開啟時鎖住背景捲動
  useEffect(() => {
    if (!drawerOpen) return;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = '';
    };
  }, [drawerOpen]);

  // 導覽連結清單 (側欄與抽屜共用)
  const navLinks = (onNavigate?: () => void) => (
    <nav className="flex flex-col gap-1">
      {NAV.map((item) => {
        const isActive = active === item.key;
        return (
          <Link
            key={item.key}
            href={item.href}
            onClick={onNavigate}
            aria-current={isActive ? 'page' : undefined}
            className={cn(
              'flex items-center gap-3 rounded-bl-sm px-3 py-2.5 text-[15px] font-medium transition',
              isActive
                ? 'bg-bl-accent/14 text-bl-accent'
                : 'text-bl-secondary-label hover:bg-bl-fill-quaternary hover:text-bl-label',
            )}
          >
            <item.icon className="h-5 w-5" />
            <span className="flex-1">{item.label}</span>
            {item.key === 'orders' && activeCount > 0 && <BLCountBadge count={activeCount} />}
          </Link>
        );
      })}
    </nav>
  );

  return (
    <div className="min-h-screen md:flex">
      {/* 桌機：固定左側欄 */}
      <aside className="hidden md:fixed md:inset-y-0 md:flex md:w-60 md:flex-col md:border-r md:border-bl-separator md:bg-bl-secondary-background md:px-3 md:py-5">
        <div className="px-3 pb-5 text-[22px] font-bold tracking-tight text-bl-label">BuyLedger</div>
        {navLinks()}
      </aside>

      {/* 手機：黏附頂部 app bar */}
      <header className="sticky top-0 z-40 flex items-center justify-between border-b border-bl-separator bg-bl-glass-background px-4 py-3 backdrop-blur-xl md:hidden">
        <Link href="/" className="text-[19px] font-bold tracking-tight text-bl-label">
          BuyLedger
        </Link>
        <button
          type="button"
          onClick={() => setDrawerOpen(true)}
          aria-label="開啟選單"
          className="relative -mr-1 rounded-bl-sm p-1.5 text-bl-label transition active:bg-bl-fill-quaternary"
        >
          <Menu className="h-6 w-6" />
          {activeCount > 0 && (
            <span className="absolute -right-0.5 -top-0.5">
              <BLCountBadge count={activeCount} />
            </span>
          )}
        </button>
      </header>

      {/* 手機：漢堡抽屜 (左側滑出) */}
      {drawerOpen && (
        <div className="fixed inset-0 z-50 md:hidden">
          <div className="absolute inset-0 bg-black/40 backdrop-blur-[2px]" onClick={() => setDrawerOpen(false)} />
          <div className="absolute inset-y-0 left-0 flex w-72 max-w-[82%] flex-col bg-bl-secondary-background px-3 py-5 shadow-2xl">
            <div className="flex items-center justify-between px-3 pb-5">
              <span className="text-[22px] font-bold tracking-tight text-bl-label">BuyLedger</span>
              <button
                type="button"
                onClick={() => setDrawerOpen(false)}
                aria-label="關閉選單"
                className="rounded-bl-sm p-1 text-bl-secondary-label transition active:bg-bl-fill-quaternary"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
            {navLinks(() => setDrawerOpen(false))}
          </div>
        </div>
      )}

      <main className="flex-1 md:ml-60">
        <div className="mx-auto w-full max-w-7xl px-4 py-6 sm:px-6 lg:px-8 lg:py-8">{children}</div>
      </main>
    </div>
  );
}
