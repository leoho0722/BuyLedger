'use client';

import { useRouter } from 'next/navigation';
import { PageHeader } from '@/components/PageHeader';
import { CampaignEditForm } from '@/features/campaigns/CampaignEditForm';

export default function NewCampaignPage() {
  const router = useRouter();
  return (
    <div>
      <PageHeader title="新增開團" />
      <CampaignEditForm
        mode="create"
        onSaved={(c) => router.push(`/campaigns/${c.id}`)}
        onCancel={() => router.back()}
      />
    </div>
  );
}
