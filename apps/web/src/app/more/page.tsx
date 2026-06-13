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
import { BLCard } from '@/components/ds/BLCard';
import { BLListRow } from '@/components/ds/BLListRow';
import { SectionHeader } from '@/components/ds/SectionHeader';
import { PageHeader } from '@/components/PageHeader';

// 選單項定義
type MenuItem = { icon: LucideIcon; title: string; href: string };

const TOOLS: MenuItem[] = [
  { icon: Users, title: '客戶名單', href: '/more/customers' },
  { icon: ArrowLeftRight, title: '匯率工具', href: '/more/fx' },
  { icon: Calculator, title: '報價試算', href: '/more/quote' },
];

const LOOKUPS: MenuItem[] = [
  { icon: Tag, title: '商品類別', href: '/more/lookups/category' },
  { icon: Store, title: '訂單來源', href: '/more/lookups/order-source' },
  { icon: CreditCard, title: '付款方式', href: '/more/lookups/payment-method' },
  { icon: ClipboardCheck, title: '對帳狀態', href: '/more/lookups/verification-status' },
];

const SETTINGS: MenuItem[] = [{ icon: Settings, title: '設定', href: '/more/settings' }];

export default function MorePage() {
  const router = useRouter();

  // 單張卡片：列間以 border-b 分隔，末列不畫線
  const renderCard = (items: MenuItem[]) => (
    <BLCard padded={false}>
      {items.map((item, index) => (
        <div
          key={item.href}
          className={index < items.length - 1 ? 'border-b border-bl-separator' : undefined}
        >
          <BLListRow
            icon={item.icon}
            title={item.title}
            showChevron
            onClick={() => router.push(item.href)}
          />
        </div>
      ))}
    </BLCard>
  );

  return (
    <div>
      <PageHeader title="更多" />
      <div className="space-y-4">
        {renderCard(TOOLS)}
        <div className="space-y-2">
          <SectionHeader title="主檔管理" />
          {renderCard(LOOKUPS)}
        </div>
        {renderCard(SETTINGS)}
      </div>
    </div>
  );
}
