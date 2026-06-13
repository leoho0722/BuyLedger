import { Body, Controller, Post, Res } from '@nestjs/common';
import type { Response } from 'express';
import { AiSummaryInput, AiSummaryService } from './ai-summary.service';

@Controller('ai-summary')
export class AiSummaryController {
  constructor(private readonly ai: AiSummaryService) {}

  // 串流回應：前端以 fetch ReadableStream 逐塊讀取並即時渲染 Markdown。
  @Post('stream')
  async stream(@Body() body: AiSummaryInput, @Res() res: Response): Promise<void> {
    await this.ai.stream(body, res);
  }
}
