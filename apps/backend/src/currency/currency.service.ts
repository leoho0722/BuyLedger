import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NowService } from '../common/now.service';
import {
  CURRENCY_CACHE_TTL_SECONDS,
  DEFAULT_CURRENCY_CODES,
} from '../domain/constants';

// 匯率快照 DTO (rates 為 { 目標幣別: decimal 字串 })。
export interface FxSnapshotDTO {
  date: string;
  base: string;
  rates: Record<string, string>;
}

const CODES_SINGLETON = 'singleton';
const SNAPSHOT_ID = 'latest';
const API_BASE = 'https://v6.exchangerate-api.com/v6';

@Injectable()
export class CurrencyService {
  private readonly logger = new Logger(CurrencyService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly now: NowService,
  ) {}

  private get apiKey(): string {
    return (process.env.EXCHANGE_RATE_API_KEY ?? '').trim();
  }

  // 幣別清單：7 天 TTL，逾期才打 /codes；取不到時退回快取或預載 fallback。
  async getCodes(): Promise<string[]> {
    const meta = await this.prisma.currencyMetadata.findUnique({
      where: { id: CODES_SINGLETON },
    });
    const ttlMs = CURRENCY_CACHE_TTL_SECONDS * 1000;
    const fresh =
      meta?.updatedAt && this.now.now().getTime() - meta.updatedAt.getTime() < ttlMs;
    if (fresh && meta) return meta.codes;

    const fetched = await this.fetchCodes();
    if (fetched && fetched.length > 0) {
      await this.prisma.currencyMetadata.upsert({
        where: { id: CODES_SINGLETON },
        create: { id: CODES_SINGLETON, codes: fetched, updatedAt: this.now.now() },
        update: { codes: fetched, updatedAt: this.now.now() },
      });
      return fetched;
    }
    return meta?.codes?.length ? meta.codes : DEFAULT_CURRENCY_CODES;
  }

  async refreshCodes(): Promise<string[]> {
    const fetched = await this.fetchCodes();
    if (fetched && fetched.length > 0) {
      await this.prisma.currencyMetadata.upsert({
        where: { id: CODES_SINGLETON },
        create: { id: CODES_SINGLETON, codes: fetched, updatedAt: this.now.now() },
        update: { codes: fetched, updatedAt: this.now.now() },
      });
      return fetched;
    }
    return this.getCodes();
  }

  // 最新匯率：有快照直接回；無快照且有 key 時嘗試抓一次；皆無回 null (空狀態，不偽造)。
  async getLatest(): Promise<FxSnapshotDTO | null> {
    const row = await this.prisma.fxSnapshot.findUnique({ where: { id: SNAPSHOT_ID } });
    if (row) {
      return {
        date: row.date.toISOString(),
        base: row.base,
        rates: row.rates as Record<string, string>,
      };
    }
    return this.refreshRates();
  }

  async refreshRates(): Promise<FxSnapshotDTO | null> {
    if (!this.apiKey) return null;
    try {
      const res = await fetch(`${API_BASE}/${this.apiKey}/latest/TWD`);
      const json = (await res.json()) as {
        result?: string;
        base_code?: string;
        conversion_rates?: Record<string, number>;
        time_last_update_unix?: number;
      };
      if (json.result !== 'success' || !json.conversion_rates) return null;

      const rates: Record<string, string> = {};
      for (const [code, value] of Object.entries(json.conversion_rates)) {
        rates[code] = String(value);
      }
      const date = json.time_last_update_unix
        ? new Date(json.time_last_update_unix * 1000)
        : this.now.now();

      await this.prisma.fxSnapshot.upsert({
        where: { id: SNAPSHOT_ID },
        create: { id: SNAPSHOT_ID, base: 'TWD', date, rates },
        update: { base: 'TWD', date, rates },
      });
      return { date: date.toISOString(), base: 'TWD', rates };
    } catch (err) {
      this.logger.warn(`匯率取得失敗：${String(err)}`);
      return null;
    }
  }

  private async fetchCodes(): Promise<string[] | null> {
    if (!this.apiKey) return null;
    try {
      const res = await fetch(`${API_BASE}/${this.apiKey}/codes`);
      const json = (await res.json()) as {
        result?: string;
        supported_codes?: [string, string][];
      };
      if (json.result !== 'success' || !json.supported_codes) return null;
      return json.supported_codes.map((pair) => pair[0]);
    } catch (err) {
      this.logger.warn(`幣別清單取得失敗：${String(err)}`);
      return null;
    }
  }
}
