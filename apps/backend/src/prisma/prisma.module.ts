import { Global, Module } from '@nestjs/common';
import { PrismaService } from './prisma.service';

// 全域提供 PrismaService，各 feature module 直接注入
@Global()
@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class PrismaModule {}
