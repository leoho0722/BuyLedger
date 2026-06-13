import { Module } from '@nestjs/common';
import { CurrencyController, FxController } from './currency.controller';
import { CurrencyService } from './currency.service';

@Module({
  controllers: [CurrencyController, FxController],
  providers: [CurrencyService],
})
export class CurrencyModule {}
