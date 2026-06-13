import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Post,
  Put,
} from '@nestjs/common';
import { OrdersService } from './orders.service';
import {
  MergeDraftInput,
  OrderInput,
  ReceiptChangeInput,
  StatusChangeInput,
} from './orders.types';

@Controller('orders')
export class OrdersController {
  constructor(private readonly orders: OrdersService) {}

  @Get()
  list() {
    return this.orders.list();
  }

  // 合併草稿：靜態路徑置於 :id 之前避免被動態段攔截。
  @Post('merge/draft')
  mergeDraft(@Body() body: MergeDraftInput) {
    return this.orders.mergeDraft(body);
  }

  @Get(':id')
  get(@Param('id') id: string) {
    return this.orders.get(id);
  }

  @Post()
  create(@Body() body: OrderInput) {
    return this.orders.create(body);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() body: OrderInput) {
    return this.orders.update(id, body);
  }

  @Delete(':id')
  @HttpCode(204)
  async remove(@Param('id') id: string): Promise<void> {
    await this.orders.remove(id);
  }

  @Post(':id/status')
  setStatus(@Param('id') id: string, @Body() body: StatusChangeInput) {
    return this.orders.setStatus(id, body);
  }

  @Post(':id/receipt')
  setReceipt(@Param('id') id: string, @Body() body: ReceiptChangeInput) {
    return this.orders.setReceipt(id, body);
  }
}
