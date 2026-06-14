import { Body, Controller, Delete, Get, Param, Post, Put } from '@nestjs/common';
import { CurrentUid } from '../auth/current-user.decorator';
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
  listCategories(@CurrentUid() uid: string) {
    return this.lookups.listCategories(uid);
  }

  @Post('categories')
  addCategory(@CurrentUid() uid: string, @Body() body: NameInput) {
    return this.lookups.addCategory(uid, body.name ?? '');
  }

  @Put('categories/:name')
  renameCategory(@CurrentUid() uid: string, @Param('name') name: string, @Body() body: NameInput) {
    return this.lookups.renameCategory(uid, name, body.name ?? '');
  }

  @Delete('categories/:name')
  removeCategory(@CurrentUid() uid: string, @Param('name') name: string) {
    return this.lookups.removeCategory(uid, name);
  }

  // 訂單來源
  @Get('order-sources')
  listOrderSources(@CurrentUid() uid: string) {
    return this.lookups.listOrderSources(uid);
  }

  @Post('order-sources')
  addOrderSource(@CurrentUid() uid: string, @Body() body: NameInput) {
    return this.lookups.addOrderSource(uid, body.name ?? '');
  }

  @Put('order-sources/:name')
  renameOrderSource(@CurrentUid() uid: string, @Param('name') name: string, @Body() body: NameInput) {
    return this.lookups.renameOrderSource(uid, name, body.name ?? '');
  }

  @Delete('order-sources/:name')
  removeOrderSource(@CurrentUid() uid: string, @Param('name') name: string) {
    return this.lookups.removeOrderSource(uid, name);
  }

  // 對帳狀態
  @Get('verification-statuses')
  listVerificationStatuses(@CurrentUid() uid: string) {
    return this.lookups.listVerificationStatuses(uid);
  }

  @Post('verification-statuses')
  addVerificationStatus(@CurrentUid() uid: string, @Body() body: NameInput) {
    return this.lookups.addVerificationStatus(uid, body.name ?? '');
  }

  @Put('verification-statuses/:name')
  renameVerificationStatus(
    @CurrentUid() uid: string,
    @Param('name') name: string,
    @Body() body: NameInput,
  ) {
    return this.lookups.renameVerificationStatus(uid, name, body.name ?? '');
  }

  @Delete('verification-statuses/:name')
  removeVerificationStatus(@CurrentUid() uid: string, @Param('name') name: string) {
    return this.lookups.removeVerificationStatus(uid, name);
  }

  // 付款方式 (帶旗標)
  @Get('payment-methods')
  listPaymentMethods(@CurrentUid() uid: string) {
    return this.lookups.listPaymentMethods(uid);
  }

  @Post('payment-methods')
  addPaymentMethod(@CurrentUid() uid: string, @Body() body: PaymentMethodInput) {
    return this.lookups.addPaymentMethod(uid, body);
  }

  @Put('payment-methods/:name')
  updatePaymentMethod(
    @CurrentUid() uid: string,
    @Param('name') name: string,
    @Body() body: PaymentMethodInput,
  ) {
    return this.lookups.updatePaymentMethod(uid, name, body);
  }

  @Delete('payment-methods/:name')
  removePaymentMethod(@CurrentUid() uid: string, @Param('name') name: string) {
    return this.lookups.removePaymentMethod(uid, name);
  }
}
