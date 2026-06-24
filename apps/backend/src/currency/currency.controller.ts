import { Controller, Get, Post } from '@nestjs/common';
import { CurrencyService } from './currency.service';

@Controller('currency')
export class CurrencyController {
  constructor(private readonly currency: CurrencyService) {}

  @Get('codes')
  codes() {
    return this.currency.getCodes();
  }

  @Post('codes/refresh')
  refreshCodes() {
    return this.currency.refreshCodes();
  }
}

@Controller('fx')
export class FxController {
  constructor(private readonly currency: CurrencyService) {}

  // 最新匯率快照；無資料回 null (前端顯示「尚無可用匯率資料」空狀態)
  @Get('latest')
  latest() {
    return this.currency.getLatest();
  }

  @Post('refresh')
  refresh() {
    return this.currency.refreshRates();
  }
}
