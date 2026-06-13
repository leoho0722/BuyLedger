'use client';

import { useRouter } from 'next/navigation';
import {
  ArrowLeftRight,
  Calculator,
  ClipboardCheck,
  CreditCard,
  Settings,
  Store,
  Tag,
  Users,
  type LucideIcon,
} from 'lucide-react';
import { SectionHeader } from '@/components/ds/SectionHeader';
import { PageHeader } from '@/components/PageHeader';

// 選單項定義 (含一句說明，呈現為 Web 工具卡片)。
type MenuItem = { icon: LucideIcon; title: string; description: string; href: string };

const TOOLS: MenuItem[] = [
  { icon: Users, title: '客戶名單', description: '依客戶檢視消費與訂單', href: '/more/customers' },
  { icon: ArrowLeftRight, title: '匯率工具', description: '外幣即時換算', href: '/more/fx' },
  { icon: Calculator, title: '報價試算', description: '由成本與費率算建議售價', href: '/more/quote' },
  { icon: Settings, title: '設定', description: '外觀、通知、目標與 AI', href: '/more/settings' },
];

const LOOKUPS: MenuItem[] = [
  { icon: Tag, title: '商品類別', description: '管理可選的商品類別', href: '/more/lookups/category' },
  { icon: Store, title: '訂單來源', description: '管理可選的訂單來源', href: '/more/lookups/order-source' },
  { icon: CreditCard, title: '付款方式', description: '管理付款方式與屬性', href: '/more/lookups/payment-method' },
  { icon: ClipboardCheck, title: '對帳狀態', description: '管理可選的對帳狀態', href: '/more/lookups/verification-status' },
];

export default function MorePage() {
  const router = useRouter();

  // 工具卡片網格：圖示色塊 + 標題 + 說明，hover 浮起 (Web 風格，非 iOS 清單列)。
  const grid = (items: MenuItem[]) => (
    <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
      {items.map((item) => (
        <button
          key={item.href}
          type="button"
          onClick={() => router.push(item.href)}
          className="flex flex-col gap-3 rounded-bl-lg border-[0.5px] border-bl-separator bg-bl-surface p-4 text-left bl-card-shadow transition hover:border-bl-accent/30 hover:bl-card-shadow-floating"
        >
          <span className="flex h-10 w-10 items-center justify-center rounded-bl-md bg-bl-accent/14 text-bl-accent">
            <item.icon className="h-5 w-5" strokeWidth={2} />
          </span>
          <div className="space-y-0.5">
            <p className="text-[15px] font-semibold text-bl-label">{item.title}</p>
            <p className="text-[13px] text-bl-secondary-label">{item.description}</p>
          </div>
        </button>
      ))}
    </div>
  );

  return (
    <div className="space-y-6">
      <PageHeader title="更多" />
      <div className="space-y-2">
        <SectionHeader title="工具" />
        {grid(TOOLS)}
      </div>
      <div className="space-y-2">
        <SectionHeader title="主檔管理" />
        {grid(LOOKUPS)}
      </div>
    </div>
  );
}
