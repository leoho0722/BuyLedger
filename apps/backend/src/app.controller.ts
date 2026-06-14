import { Controller, Get } from '@nestjs/common';
import { Public } from './auth/public.decorator';

@Controller()
export class AppController {
  // 健康檢查不需驗證，標記為公開端點。
  @Public()
  @Get('health')
  health(): { status: string } {
    return { status: 'ok' };
  }
}
