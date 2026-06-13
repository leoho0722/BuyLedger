'use client';

import { BarChart3, House, Menu, Package, ReceiptText } from 'lucide-react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
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

  return (
    <div className="min-h-screen md:flex">
      <aside className="hidden md:fixed md:inset-y-0 md:flex md:w-60 md:flex-col md:border-r md:border-bl-separator md:bg-bl-secondary-background md:px-3 md:py-5">
        <div className="px-3 pb-5 text-[22px] font-bold text-bl-label">BuyLedger</div>
        <nav className="flex flex-col gap-1">
          {NAV.map((item) => {
            const isActive = active === item.key;
            return (
              <Link
                key={item.key}
                href={item.href}
                className={cn(
                  'flex items-center gap-3 rounded-bl-sm px-3 py-2.5 text-[15px] font-medium transition',
                  isActive ? 'bg-bl-accent/14 text-bl-accent' : 'text-bl-secondary-label hover:bg-bl-fill-quaternary',
                )}
              >
                <item.icon className="h-5 w-5" />
                <span className="flex-1">{item.label}</span>
                {item.key === 'orders' && activeCount > 0 && <BLCountBadge count={activeCount} />}
              </Link>
            );
          })}
        </nav>
      </aside>

      <main className="flex-1 pb-24 md:ml-60 md:pb-0">
        <div className="mx-auto max-w-3xl px-4 py-5 md:py-8">{children}</div>
      </main>

      <nav className="fixed inset-x-0 bottom-0 z-40 flex border-t border-bl-separator bg-bl-glass-background backdrop-blur-xl md:hidden">
        {NAV.map((item) => {
          const isActive = active === item.key;
          return (
            <Link
              key={item.key}
              href={item.href}
              className={cn(
                'relative flex flex-1 flex-col items-center gap-0.5 py-2 pb-[max(0.5rem,env(safe-area-inset-bottom))] text-[10px]',
                isActive ? 'text-bl-accent' : 'text-bl-secondary-label',
              )}
            >
              <item.icon className="h-6 w-6" />
              <span>{item.label}</span>
              {item.key === 'orders' && activeCount > 0 && (
                <span className="absolute right-[22%] top-1">
                  <BLCountBadge count={activeCount} />
                </span>
              )}
            </Link>
          );
        })}
      </nav>
    </div>
  );
}
