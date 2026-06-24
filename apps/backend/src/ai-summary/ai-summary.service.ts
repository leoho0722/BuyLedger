import { Injectable, Logger } from '@nestjs/common';
import type { Response } from 'express';
import { PrismaService } from '../prisma/prisma.service';
import { rowToDomain } from '../orders/order.mapper';
import { DEFAULT_AI_MODEL } from '../domain/constants';
import type { LedgerOrder } from '../data-model';

export interface AiSummaryInput {
  orderIds?: string[];
  selectedCategory?: string | null;
}

const OLLAMA_ENDPOINT = 'https://ollama.com/api/chat';
const MAX_DIGEST_ITEMS = 200;

@Injectable()
export class AiSummaryService {
  private readonly logger = new Logger(AiSummaryService.name);

  constructor(private readonly prisma: PrismaService) {}

  // 串流 AI 商品明細總結到 res；缺 key 時回 400 讓前端顯示失敗狀態 (不偽造內容)
  async stream(uid: string, input: AiSummaryInput, res: Response): Promise<void> {
    const apiKey = (process.env.OLLAMA_API_KEY ?? '').trim();
    if (!apiKey) {
      res.status(400).json({ error: 'missing_key', message: '尚未設定 AI 服務金鑰' });
      return;
    }

    const orderIds = input.orderIds ?? [];
    const orders = await this.loadOrders(uid, orderIds);
    const prompt = this.buildPrompt(orders, input.selectedCategory ?? null);
    const model = await this.resolveModel(uid);

    const controller = new AbortController();
    res.on('close', () => controller.abort());

    try {
      const upstream = await fetch(OLLAMA_ENDPOINT, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model,
          messages: [{ role: 'user', content: prompt }],
          stream: true,
        }),
        signal: controller.signal,
      });

      if (!upstream.ok || !upstream.body) {
        res.status(upstream.status === 401 || upstream.status === 403 ? 401 : 502).json({
          error: 'upstream_error',
          message: `AI 服務回應錯誤 (${upstream.status})`,
        });
        return;
      }

      res.setHeader('Content-Type', 'text/plain; charset=utf-8');
      res.setHeader('Cache-Control', 'no-cache, no-transform');
      res.setHeader('X-Accel-Buffering', 'no');
      res.flushHeaders?.();

      const reader = upstream.body.getReader();
      const decoder = new TextDecoder();
      let buffer = '';
      for (;;) {
        const { done, value } = await reader.read();
        if (done) break;
        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');
        buffer = lines.pop() ?? '';
        for (const line of lines) {
          const trimmed = line.trim();
          if (!trimmed) continue;
          const finished = this.writeChunk(trimmed, res);
          if (finished) {
            res.end();
            return;
          }
        }
      }
      res.end();
    } catch (err) {
      if (controller.signal.aborted) {
        // 前端關閉串流屬正常取消，不視為錯誤
        return;
      }
      this.logger.warn(`AI 串流失敗：${String(err)}`);
      if (!res.headersSent) {
        res.status(502).json({ error: 'transport_error', message: 'AI 服務連線失敗' });
      } else {
        res.end();
      }
    }
  }

  // 解析一行 NDJSON，寫出 content，回傳是否已完成
  private writeChunk(line: string, res: Response): boolean {
    try {
      const json = JSON.parse(line) as { message?: { content?: string }; done?: boolean };
      const content = json.message?.content;
      if (content) res.write(content);
      return json.done === true;
    } catch {
      return false;
    }
  }

  private async loadOrders(uid: string, orderIds: string[]): Promise<LedgerOrder[]> {
    if (orderIds.length === 0) return [];
    const rows = await this.prisma.order.findMany({
      where: { id: { in: orderIds }, ownerUid: uid },
    });
    const map = new Map(rows.map((r) => [r.id, rowToDomain(r)]));
    return orderIds.map((id) => map.get(id)).filter((o): o is LedgerOrder => Boolean(o));
  }

  private async resolveModel(uid: string): Promise<string> {
    const settings = await this.prisma.settings.findUnique({ where: { ownerUid: uid } });
    return settings?.aiSummaryModel || DEFAULT_AI_MODEL;
  }

  // 組商品明細 digest (對齊 iOS aiItemsDigest)
  private buildDigest(orders: LedgerOrder[]): string {
    const lines: string[] = [];
    let totalItems = 0;
    for (const order of orders) {
      totalItems += order.items.length;
    }
    outer: for (const order of orders) {
      const categoryNames = order.categories.map((c) => c.trim()).filter(Boolean);
      const categoryTag = categoryNames.length ? categoryNames.join('、') : '未分類';
      for (const item of order.items) {
        const name = item.name.trim() || '未命名商品';
        lines.push(`- [${categoryTag}] ${name} x${item.quantity} @ ${item.unitPrice} ${order.currency}`);
        if (lines.length >= MAX_DIGEST_ITEMS) break outer;
      }
    }
    if (lines.length === 0) return '(目前列表沒有任何商品明細)';
    let digest = lines.join('\n');
    if (totalItems > lines.length) {
      digest += `\n…(其餘 ${totalItems - lines.length} 個品項未列出)`;
    }
    return digest;
  }

  // 組完整 prompt (對齊 iOS aiSummaryPrompt)
  private buildPrompt(orders: LedgerOrder[], selectedCategory: string | null): string {
    const categoryScope = selectedCategory
      ? `(已篩選類別：${selectedCategory})`
      : '(涵蓋目前列表所有類別)';
    return `你是個人代購 App 的分析助理。以下是目前訂單列表的商品明細${categoryScope}，每行格式為「- [類別] 商品名稱 x數量 @ 單價 幣別」：

${this.buildDigest(orders)}

請用正體中文、以 Markdown 格式總結這些商品明細，內容包含：
- 一個 \`##\` 層級的標題
- 各品項的品名以及購買的總數量 (如果品名有編號的話，請照編號排序；如果沒有編號的話，請照字母順序排序)

請以條列與粗體強調重點，全文控制在約 200–300 字。只根據上面提供的資料作答，不要杜撰未出現的商品、數字或結論。`;
  }
}
