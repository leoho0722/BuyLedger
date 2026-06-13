'use client';

import { useParams, useRouter } from 'next/navigation';
import { PageHeader } from '@/components/PageHeader';
import { CampaignEditForm } from '@/features/campaigns/CampaignEditForm';
import { useCampaign } from '@/lib/queries';

export default function EditCampaignPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const { data: campaign, isLoading } = useCampaign(id);

  if (isLoading || !campaign) {
    return <p className="py-12 text-center text-bl-secondary-label">載入中…</p>;
  }

  return (
    <div>
      <PageHeader title="編輯開團" />
      <CampaignEditForm
        mode="edit"
        campaignId={id}
        initial={{
          name: campaign.name,
          openDate: campaign.openDate,
          closeDate: campaign.closeDate ?? null,
          notes: campaign.notes,
        }}
        onSaved={() => router.push(`/campaigns/${id}`)}
        onCancel={() => router.back()}
      />
    </div>
  );
}
