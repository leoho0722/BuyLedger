'use client';

import { Loader2, RotateCw, Sparkles } from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { BLButton } from '@/components/ds/BLButton';
import { Sheet } from '@/components/ds/Sheet';
import { api } from '@/lib/api';

type Phase = 'streaming' | 'done' | 'error';

// AI 商品明細總結 sheet：串流渲染 Markdown，關閉即取消串流
export function AiSummarySheet({
  open,
  onClose,
  orderIds,
  selectedCategory,
}: {
  open: boolean;
  onClose: () => void;
  orderIds: string[];
  selectedCategory: string | null;
}) {
  const [text, setText] = useState('');
  const [phase, setPhase] = useState<Phase>('streaming');
  const [error, setError] = useState('');
  const [attempt, setAttempt] = useState(0);
  const controller = useRef<AbortController | null>(null);

  useEffect(() => {
    if (!open) return;
    const c = new AbortController();
    controller.current = c;
    setText('');
    setError('');
    setPhase('streaming');
    api.aiSummary
      .stream(orderIds, selectedCategory, (chunk) => setText((prev) => prev + chunk), c.signal)
      .then(() => setPhase('done'))
      .catch((e: unknown) => {
        if (c.signal.aborted) return;
        setPhase('error');
        setError(e instanceof Error ? e.message : 'AI 總結失敗');
      });
    return () => c.abort();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, attempt]);

  return (
    <Sheet
      open={open}
      onClose={onClose}
      title={
        <span className="inline-flex items-center gap-1.5">
          <Sparkles className="h-4 w-4 text-bl-accent" />
          AI 商品明細總結
        </span>
      }
    >
      <div className="space-y-3">
        {phase === 'error' ? (
          <div className="space-y-3 py-6 text-center">
            <p className="text-[15px] text-bl-secondary-label">{error}</p>
            <BLButton variant="secondary" onClick={() => setAttempt((a) => a + 1)}>
              <RotateCw className="h-4 w-4" />
              重試
            </BLButton>
          </div>
        ) : (
          <>
            {phase === 'streaming' && (
              <div className="flex items-center gap-2 text-sm text-bl-secondary-label">
                <Loader2 className="h-4 w-4 animate-spin" />
                產生中…
              </div>
            )}
            <div className="prose-bl text-[15px] leading-relaxed text-bl-label">
              <ReactMarkdown remarkPlugins={[remarkGfm]}>{text}</ReactMarkdown>
            </div>
            <p className="border-t border-bl-separator pt-3 text-xs text-bl-tertiary-label">
              此內容由 AI 生成，可能包含錯誤資訊，請自行核對。
            </p>
          </>
        )}
      </div>
    </Sheet>
  );
}
