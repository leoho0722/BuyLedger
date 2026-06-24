import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { FirebaseModule } from './firebase/firebase.module';
import { AuthModule } from './auth/auth.module';
import { PrismaModule } from './prisma/prisma.module';
import { CommonModule } from './common/now.service';
import { SyncModule } from './sync/sync.module';
import { OrdersModule } from './orders/orders.module';
import { CampaignsModule } from './campaigns/campaigns.module';
import { LookupsModule } from './lookups/lookups.module';
import { CurrencyModule } from './currency/currency.module';
import { AiSummaryModule } from './ai-summary/ai-summary.module';
import { SettingsModule } from './settings/settings.module';
import { DevModule } from './dev/dev.module';
import { AppController } from './app.controller';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ScheduleModule.forRoot(),
    FirebaseModule,
    AuthModule,
    PrismaModule,
    CommonModule,
    SyncModule,
    OrdersModule,
    CampaignsModule,
    LookupsModule,
    CurrencyModule,
    AiSummaryModule,
    SettingsModule,
    DevModule,
  ],
  controllers: [AppController],
})
export class AppModule {}
