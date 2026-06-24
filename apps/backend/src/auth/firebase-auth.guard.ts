import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { FirebaseService } from '../firebase/firebase.service';
import { IS_PUBLIC_KEY } from './public.decorator';

// 帶有已驗證 uid 的請求；guard 通過後 uid 必定存在 (供 task 2.3 的存取器取用)
export interface AuthenticatedRequest {
  headers: Record<string, string | undefined>;
  uid?: string;
}

// 對齊 spec「Backend verifies Firebase ID tokens on protected endpoints」：
// 全域套用，預設所有端點都需驗證；@Public() 標記的端點略過
// 解析 Authorization: Bearer，verifyIdToken 成功才放行並注入 uid；否則一律 401
@Injectable()
export class FirebaseAuthGuard implements CanActivate {
  constructor(
    private readonly firebase: FirebaseService,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) {
      return true;
    }

    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const token = this.extractBearerToken(request.headers?.authorization);
    if (!token) {
      throw new UnauthorizedException('缺少 Firebase ID token');
    }

    try {
      const decoded = await this.firebase.auth.verifyIdToken(token);
      request.uid = decoded.uid;
      return true;
    } catch {
      // 不回傳內部驗證細節，僅以 401 表示驗證失敗
      throw new UnauthorizedException('Firebase ID token 驗證失敗');
    }
  }

  private extractBearerToken(authorization?: string): string | null {
    if (!authorization) {
      return null;
    }
    const [scheme, token] = authorization.split(' ');
    if (scheme !== 'Bearer' || !token) {
      return null;
    }
    return token;
  }
}
