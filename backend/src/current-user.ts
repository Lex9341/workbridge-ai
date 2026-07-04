import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import type { Request } from 'express';

import { DEMO_USER_ID } from './store.service';

export const CurrentUserId = createParamDecorator((_data: unknown, ctx: ExecutionContext): string => {
  const request = ctx.switchToHttp().getRequest<Request & { user?: { sub?: string } }>();
  return request.user?.sub ?? DEMO_USER_ID;
});
