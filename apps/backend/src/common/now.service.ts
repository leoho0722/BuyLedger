import { Global, Injectable, Module } from '@nestjs/common';
import { randomUUID } from 'node:crypto';

// 「現在」時間注入點 (對齊跨平台環境相依注入鐵則)：production 走系統時鐘，
// dev/seed 可用 BUYLEDGER_FIXED_NOW (ISO) 固定，確保可重現
@Injectable()
export class NowService {
  now(): Date {
    const fixed = process.env.BUYLEDGER_FIXED_NOW;
    if (fixed) {
      const parsed = new Date(fixed);
      if (!Number.isNaN(parsed.getTime())) {
        return parsed;
      }
    }
    return new Date();
  }
}

// UUID/隨機數注入點。訂單編號等 surrogate id 經此產生
@Injectable()
export class IdService {
  uuid(): string {
    return randomUUID();
  }

  // 訂單編號：BL- + 6 碼大寫 (對齊 iOS「BL-DRAFT-」風格的精簡版)
  newOrderId(): string {
    return `BL-${this.uuid().replace(/-/g, '').slice(0, 6).toUpperCase()}`;
  }
}

@Global()
@Module({
  providers: [NowService, IdService],
  exports: [NowService, IdService],
})
export class CommonModule {}
