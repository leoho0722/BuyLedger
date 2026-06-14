import { SetMetadata } from '@nestjs/common';

// 標記不需身分驗證的公開端點 (如健康檢查、根路由)；全域 FirebaseAuthGuard 會略過這些路由。
export const IS_PUBLIC_KEY = 'isPublic';
export const Public = (): MethodDecorator & ClassDecorator =>
  SetMetadata(IS_PUBLIC_KEY, true);
