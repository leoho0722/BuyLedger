import 'reflect-metadata';
import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import type { NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // 訂單照片以 base64 內嵌，放寬 body 上限。
  app.useBodyParser('json', { limit: '50mb' });

  app.setGlobalPrefix('api');

  // 前端來源 CORS (預設 localhost:3000)。
  app.enableCors({
    origin: process.env.WEB_ORIGIN?.split(',').map((s) => s.trim()) ?? true,
    credentials: true,
  });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: false,
    }),
  );

  const port = Number(process.env.PORT ?? 4000);
  await app.listen(port, '0.0.0.0');
  // eslint-disable-next-line no-console
  console.log(`BuyLedger backend listening on :${port}`);
}

void bootstrap();
