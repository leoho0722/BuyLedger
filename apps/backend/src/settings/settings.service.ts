import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { D, Decimal } from '../domain/decimal';
import {
  AI_MODEL_CANDIDATES,
  DEFAULT_AI_MODEL,
  DEFAULT_CURRENCY,
  DEFAULT_MONTHLY_PROFIT_GOAL,
} from '../domain/constants';

export interface SettingsDTO {
  appearance: 'system' | 'light' | 'dark';
  notifications: boolean;
  useAiSummary: boolean;
  aiSummaryModel: string;
  defaultCurrency: string;
  monthlyProfitGoal: string;
  aiModelCandidates: string[];
}

export interface SettingsInput {
  appearance?: 'system' | 'light' | 'dark';
  notifications?: boolean;
  useAiSummary?: boolean;
  aiSummaryModel?: string;
  defaultCurrency?: string;
  monthlyProfitGoal?: string;
}

const SINGLETON = 'singleton';

@Injectable()
export class SettingsService {
  constructor(private readonly prisma: PrismaService) {}

  async get(): Promise<SettingsDTO> {
    const row = await this.prisma.settings.upsert({
      where: { id: SINGLETON },
      create: { id: SINGLETON },
      update: {},
    });
    return {
      appearance: row.appearance as SettingsDTO['appearance'],
      notifications: row.notifications,
      useAiSummary: row.useAiSummary,
      aiSummaryModel: row.aiSummaryModel || DEFAULT_AI_MODEL,
      defaultCurrency: row.defaultCurrency || DEFAULT_CURRENCY,
      monthlyProfitGoal: row.monthlyProfitGoal.toString(),
      aiModelCandidates: AI_MODEL_CANDIDATES,
    };
  }

  async update(input: SettingsInput): Promise<SettingsDTO> {
    const goal =
      input.monthlyProfitGoal !== undefined
        ? Decimal.max(0, D(input.monthlyProfitGoal)).toString()
        : undefined;
    await this.prisma.settings.upsert({
      where: { id: SINGLETON },
      create: {
        id: SINGLETON,
        appearance: input.appearance ?? 'system',
        notifications: input.notifications ?? true,
        useAiSummary: input.useAiSummary ?? false,
        aiSummaryModel: input.aiSummaryModel ?? DEFAULT_AI_MODEL,
        defaultCurrency: input.defaultCurrency ?? DEFAULT_CURRENCY,
        monthlyProfitGoal: goal ?? DEFAULT_MONTHLY_PROFIT_GOAL,
      },
      update: {
        appearance: input.appearance,
        notifications: input.notifications,
        useAiSummary: input.useAiSummary,
        aiSummaryModel: input.aiSummaryModel,
        defaultCurrency: input.defaultCurrency,
        monthlyProfitGoal: goal,
      },
    });
    return this.get();
  }
}
