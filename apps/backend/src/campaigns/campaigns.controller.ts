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
import { CurrentUid } from '../auth/current-user.decorator';
import {
  CampaignInput,
  CampaignStatusInput,
  CampaignsService,
} from './campaigns.service';

@Controller('campaigns')
export class CampaignsController {
  constructor(private readonly campaigns: CampaignsService) {}

  @Get()
  list(@CurrentUid() uid: string) {
    return this.campaigns.list(uid);
  }

  @Get(':id')
  get(@CurrentUid() uid: string, @Param('id') id: string) {
    return this.campaigns.get(uid, id);
  }

  @Post()
  create(@CurrentUid() uid: string, @Body() body: CampaignInput) {
    return this.campaigns.create(uid, body);
  }

  @Put(':id')
  update(@CurrentUid() uid: string, @Param('id') id: string, @Body() body: CampaignInput) {
    return this.campaigns.update(uid, id, body);
  }

  @Delete(':id')
  @HttpCode(204)
  async remove(@CurrentUid() uid: string, @Param('id') id: string): Promise<void> {
    await this.campaigns.remove(uid, id);
  }

  @Post(':id/settle')
  settle(@CurrentUid() uid: string, @Param('id') id: string) {
    return this.campaigns.settle(uid, id);
  }

  @Post(':id/status')
  setStatus(@CurrentUid() uid: string, @Param('id') id: string, @Body() body: CampaignStatusInput) {
    return this.campaigns.setStatus(uid, id, body);
  }
}
