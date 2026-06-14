import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { extractUid } from './current-user.decorator';

// 對齊 spec「Authenticated request context exposes the caller uid」：
// guard 注入的 uid 可被取出供 controller/service 使用；未受保護 (無 uid) 時視為設定錯誤。
describe('extractUid', () => {
  function ctxWith(uid?: string): ExecutionContext {
    return {
      switchToHttp: () => ({ getRequest: () => ({ headers: {}, uid }) }),
    } as unknown as ExecutionContext;
  }

  it('returns the uid attached by the guard', () => {
    expect(extractUid(ctxWith('user-9'))).toBe('user-9');
  });

  it('throws when uid is absent (endpoint not guarded)', () => {
    expect(() => extractUid(ctxWith(undefined))).toThrow(UnauthorizedException);
  });
});
