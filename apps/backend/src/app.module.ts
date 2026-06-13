import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './prisma/prisma.module';
import { CommonModule } from './common/now.service';
import { OrdersModule } from './orders/orders.module';
import { CampaignsModule } from './campaigns/campaigns.module';
import { LookupsModule } from './lookups/lookups.module';
import { CurrencyModule } from './currency/currency.module';
import { AiSummaryModule } from './ai-summary/ai-summary.module';
import { SettingsModule } from './settings/settings.module';
import { AppController } from './app.controller';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    CommonModule,
    OrdersModule,
    CampaignsModule,
    LookupsModule,
    CurrencyModule,
    AiSummaryModule,
    SettingsModule,
  ],
  controllers: [AppController],
})
export class AppModule {}
