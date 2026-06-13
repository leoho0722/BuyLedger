import { Body, Controller, Get, Put } from '@nestjs/common';
import { SettingsInput, SettingsService } from './settings.service';

@Controller('settings')
export class SettingsController {
  constructor(private readonly settings: SettingsService) {}

  @Get()
  get() {
    return this.settings.get();
  }

  @Put()
  update(@Body() body: SettingsInput) {
    return this.settings.update(body);
  }
}
