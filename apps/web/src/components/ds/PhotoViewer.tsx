'use client';

import { BLButton } from './BLButton';
import { Sheet } from './Sheet';

// 照片檢視器：以 sheet 呈現，title 顯示計數 (x / n)、上一張/下一張切換 (對齊 iOS BLPhotoViewer)。
export function PhotoViewer({
  photos,
  index,
  onIndex,
  onClose,
}: {
  photos: string[];
  index: number;
  onIndex: (i: number) => void;
  onClose: () => void;
}) {
  return (
    <Sheet open onClose={onClose} title={`${index + 1} / ${photos.length}`}>
      <div className="space-y-3">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src={photos[index]} alt="照片" className="mx-auto max-h-[60vh] rounded-bl-md object-contain" />
        <div className="flex justify-between">
          <BLButton variant="plain" onClick={() => onIndex(Math.max(0, index - 1))} disabled={index === 0}>
            上一張
          </BLButton>
          <BLButton
            variant="plain"
            onClick={() => onIndex(Math.min(photos.length - 1, index + 1))}
            disabled={index === photos.length - 1}
          >
            下一張
          </BLButton>
        </div>
      </div>
    </Sheet>
  );
}
