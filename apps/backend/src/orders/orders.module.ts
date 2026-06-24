import { Module } from '@nestjs/common';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { MirrorSweepService } from '../sync/mirror-sweep.service';

// MirrorSweepService 註冊於此 (而非 SyncModule) 以注入 OrdersService
@Module({
  controllers: [OrdersController],
  providers: [OrdersService, MirrorSweepService],
  exports: [OrdersService],
})
export class OrdersModule {}
