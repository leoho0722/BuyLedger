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
import {
  CampaignInput,
  CampaignStatusInput,
  CampaignsService,
} from './campaigns.service';

@Controller('campaigns')
export class CampaignsController {
  constructor(private readonly campaigns: CampaignsService) {}

  @Get()
  list() {
    return this.campaigns.list();
  }

  @Get(':id')
  get(@Param('id') id: string) {
    return this.campaigns.get(id);
  }

  @Post()
  create(@Body() body: CampaignInput) {
    return this.campaigns.create(body);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() body: CampaignInput) {
    return this.campaigns.update(id, body);
  }

  @Delete(':id')
  @HttpCode(204)
  async remove(@Param('id') id: string): Promise<void> {
    await this.campaigns.remove(id);
  }

  @Post(':id/settle')
  settle(@Param('id') id: string) {
    return this.campaigns.settle(id);
  }

  @Post(':id/status')
  setStatus(@Param('id') id: string, @Body() body: CampaignStatusInput) {
    return this.campaigns.setStatus(id, body);
  }
}
