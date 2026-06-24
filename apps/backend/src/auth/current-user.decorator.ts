import {
  createParamDecorator,
  ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';
import type { AuthenticatedRequest } from './firebase-auth.guard';

// 從請求情境取出 guard 注入的 uid。獨立成函式以利單元測試
export function extractUid(context: ExecutionContext): string {
  const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
  const uid = request.uid;
  if (!uid) {
    // FirebaseAuthGuard 通過後 uid 必定存在；缺 uid 代表此端點未受保護，屬設定錯誤
    throw new UnauthorizedException('請求情境缺少已驗證的 uid');
  }
  return uid;
}

// controller 以 @CurrentUid() 取得呼叫者 uid，再傳入 service 做按 uid 圈選
export const CurrentUid = createParamDecorator(
  (_data: unknown, context: ExecutionContext): string => extractUid(context),
);
