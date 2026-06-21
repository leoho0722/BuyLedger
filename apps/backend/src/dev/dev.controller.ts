import {
  Body,
  Controller,
  NotFoundException,
  Post,
} from '@nestjs/common';

import { Public } from '../auth/public.decorator';
import { FirebaseService } from '../firebase/firebase.service';

// 簽發 dev token 的請求 body：可選帶要冒充的 uid，省略時退回 demo-user。
interface DevTokenInput {
  uid?: string;
}

// Dev-only：鑄一個 Firebase custom token 供 web 以 signInWithCustomToken 自動登入，繞過互動式
// Google/Apple OAuth (CDP 控制的瀏覽器無法完成 OAuth)，僅供本機演示與自動驗證。
//
// 安全：此端點等同「無條件簽發任意 uid 的身分」，**預設關閉**——僅當執行期環境變數
// DEV_AUTH_ENABLED === 'true' 才啟用；否則一律回 404 (不洩漏其存在)。絕不可於 production
// 啟用。token 簽發走 firebase-admin 服務帳號，web 端再以同專案 signInWithCustomToken 換 ID token。
@Controller('dev')
export class DevController {
  constructor(private readonly firebase: FirebaseService) {}

  // 簽發指定 uid 的 custom token (公開端點、繞過全域 guard)。
  @Public()
  @Post('token')
  async token(@Body() body: DevTokenInput): Promise<{ token: string; uid: string }> {
    // env gate：未顯式啟用時一律回 404，不洩漏端點存在。
    if (process.env.DEV_AUTH_ENABLED !== 'true') {
      throw new NotFoundException();
    }
    const uid = (body?.uid ?? '').trim() || 'demo-user';
    const token = await this.firebase.auth.createCustomToken(uid);
    return { token, uid };
  }
}
