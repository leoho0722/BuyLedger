import { Global, Module } from '@nestjs/common';

import { HlcService } from './hlc.service';

// 跨裝置同步基礎設施：全域提供 HLC 權威端 (HlcService)，供 OrdersService /
// CampaignsService 等領域 service 注入，維持單一伺服器 lastIssued
@Global()
@Module({
  providers: [HlcService],
  exports: [HlcService],
})
export class SyncModule {}
