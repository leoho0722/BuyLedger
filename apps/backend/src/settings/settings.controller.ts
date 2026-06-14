import { Body, Controller, Get, Put } from '@nestjs/common';
import { CurrentUid } from '../auth/current-user.decorator';
import { SettingsInput, SettingsService } from './settings.service';

@Controller('settings')
export class SettingsController {
  constructor(private readonly settings: SettingsService) {}

  @Get()
  get(@CurrentUid() uid: string) {
    return this.settings.get(uid);
  }

  @Put()
  update(@CurrentUid() uid: string, @Body() body: SettingsInput) {
    return this.settings.update(uid, body);
  }
}
