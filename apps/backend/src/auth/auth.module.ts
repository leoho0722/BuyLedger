import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { FirebaseAuthGuard } from './firebase-auth.guard';

// 全域註冊 FirebaseAuthGuard：所有端點預設需驗證，@Public() 端點除外。
// FirebaseService 由全域 FirebaseModule 提供、Reflector 由 Nest core 提供。
@Module({
  providers: [{ provide: APP_GUARD, useClass: FirebaseAuthGuard }],
})
export class AuthModule {}
