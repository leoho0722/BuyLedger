import { Body, Controller, Delete, Get, Param, Post, Put } from '@nestjs/common';
import {
  LookupsService,
  NameInput,
  PaymentMethodInput,
} from './lookups.service';

@Controller('lookups')
export class LookupsController {
  constructor(private readonly lookups: LookupsService) {}

  // 商品類別
  @Get('categories')
  listCategories() {
    return this.lookups.listCategories();
  }

  @Post('categories')
  addCategory(@Body() body: NameInput) {
    return this.lookups.addCategory(body.name ?? '');
  }

  @Put('categories/:name')
  renameCategory(@Param('name') name: string, @Body() body: NameInput) {
    return this.lookups.renameCategory(name, body.name ?? '');
  }

  @Delete('categories/:name')
  removeCategory(@Param('name') name: string) {
    return this.lookups.removeCategory(name);
  }

  // 訂單來源
  @Get('order-sources')
  listOrderSources() {
    return this.lookups.listOrderSources();
  }

  @Post('order-sources')
  addOrderSource(@Body() body: NameInput) {
    return this.lookups.addOrderSource(body.name ?? '');
  }

  @Put('order-sources/:name')
  renameOrderSource(@Param('name') name: string, @Body() body: NameInput) {
    return this.lookups.renameOrderSource(name, body.name ?? '');
  }

  @Delete('order-sources/:name')
  removeOrderSource(@Param('name') name: string) {
    return this.lookups.removeOrderSource(name);
  }

  // 對帳狀態
  @Get('verification-statuses')
  listVerificationStatuses() {
    return this.lookups.listVerificationStatuses();
  }

  @Post('verification-statuses')
  addVerificationStatus(@Body() body: NameInput) {
    return this.lookups.addVerificationStatus(body.name ?? '');
  }

  @Put('verification-statuses/:name')
  renameVerificationStatus(@Param('name') name: string, @Body() body: NameInput) {
    return this.lookups.renameVerificationStatus(name, body.name ?? '');
  }

  @Delete('verification-statuses/:name')
  removeVerificationStatus(@Param('name') name: string) {
    return this.lookups.removeVerificationStatus(name);
  }

  // 付款方式 (帶旗標)
  @Get('payment-methods')
  listPaymentMethods() {
    return this.lookups.listPaymentMethods();
  }

  @Post('payment-methods')
  addPaymentMethod(@Body() body: PaymentMethodInput) {
    return this.lookups.addPaymentMethod(body);
  }

  @Put('payment-methods/:name')
  updatePaymentMethod(@Param('name') name: string, @Body() body: PaymentMethodInput) {
    return this.lookups.updatePaymentMethod(name, body);
  }

  @Delete('payment-methods/:name')
  removePaymentMethod(@Param('name') name: string) {
    return this.lookups.removePaymentMethod(name);
  }
}
