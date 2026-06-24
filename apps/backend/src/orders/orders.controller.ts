import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  Put,
} from '@nestjs/common';
import { CurrentUid } from '../auth/current-user.decorator';
import { OrdersService } from './orders.service';
import {
  BatchStatusChangeInput,
  MergeDraftInput,
  OrderInput,
  OrderPatchInput,
  ReceiptChangeInput,
  StatusChangeInput,
} from './orders.types';

@Controller('orders')
export class OrdersController {
  constructor(private readonly orders: OrdersService) {}

  @Get()
  list(@CurrentUid() uid: string) {
    return this.orders.list(uid);
  }

  // 合併草稿：靜態路徑置於 :id 之前避免被動態段攔截
  @Post('merge/draft')
  mergeDraft(@CurrentUid() uid: string, @Body() body: MergeDraftInput) {
    return this.orders.mergeDraft(uid, body);
  }

  // 批次更改狀態：靜態路徑置於 :id 之前避免被動態段攔截
  @Post('status/batch')
  batchSetStatus(@CurrentUid() uid: string, @Body() body: BatchStatusChangeInput) {
    return this.orders.batchSetStatus(uid, body);
  }

  @Get(':id')
  get(@CurrentUid() uid: string, @Param('id') id: string) {
    return this.orders.get(uid, id);
  }

  @Post()
  create(@CurrentUid() uid: string, @Body() body: OrderInput) {
    return this.orders.create(uid, body);
  }

  @Put(':id')
  update(@CurrentUid() uid: string, @Param('id') id: string, @Body() body: OrderInput) {
    return this.orders.update(uid, id, body);
  }

  // 欄位級合併寫入：client 送 partial patch (僅變更欄位 + 每欄位 HLC)，後端逐欄合併
  @Patch(':id')
  patch(@CurrentUid() uid: string, @Param('id') id: string, @Body() body: OrderPatchInput) {
    return this.orders.patch(uid, id, body);
  }

  @Delete(':id')
  @HttpCode(204)
  async remove(@CurrentUid() uid: string, @Param('id') id: string): Promise<void> {
    await this.orders.remove(uid, id);
  }

  @Post(':id/status')
  setStatus(@CurrentUid() uid: string, @Param('id') id: string, @Body() body: StatusChangeInput) {
    return this.orders.setStatus(uid, id, body);
  }

  @Post(':id/receipt')
  setReceipt(@CurrentUid() uid: string, @Param('id') id: string, @Body() body: ReceiptChangeInput) {
    return this.orders.setReceipt(uid, id, body);
  }
}
