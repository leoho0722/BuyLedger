import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { FirestoreMirrorService } from '../firebase/firestore-mirror.service';
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

@Injectable()
export class SettingsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly mirror: FirestoreMirrorService,
  ) {}

  async get(uid: string): Promise<SettingsDTO> {
    const row = await this.prisma.settings.upsert({
      where: { ownerUid: uid },
      create: { ownerUid: uid },
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

  async update(uid: string, input: SettingsInput): Promise<SettingsDTO> {
    const goal =
      input.monthlyProfitGoal !== undefined
        ? Decimal.max(0, D(input.monthlyProfitGoal)).toString()
        : undefined;
    await this.prisma.settings.upsert({
      where: { ownerUid: uid },
      create: {
        ownerUid: uid,
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
    const dto = await this.get(uid);
    // 設定為 per-user 單一文件，以 uid 為 Firestore 文件 id 鏡像
    await this.mirror.upsert(uid, 'settings', uid, dto);
    return dto;
  }
}
