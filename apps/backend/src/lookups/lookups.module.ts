import { Module } from '@nestjs/common';
import { OrdersModule } from '../orders/orders.module';
import { LookupsController } from './lookups.controller';
import { LookupsService } from './lookups.service';

@Module({
  imports: [OrdersModule],
  controllers: [LookupsController],
  providers: [LookupsService],
})
export class LookupsModule {}
