import { Module } from '@nestjs/common';

import { DevController } from './dev.controller';

// Dev-only 輔助端點 (custom token 簽發)。FirebaseService 為全域提供，故僅需註冊 controller
// 端點本身以 DEV_AUTH_ENABLED 執行期把關，未開即 404
@Module({
  controllers: [DevController],
})
export class DevModule {}
