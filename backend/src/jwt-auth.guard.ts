import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import type { Request } from 'express';
import { requireAuth } from './runtime-config';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private readonly jwt: JwtService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request & { user?: { sub: string; email?: string } }>();
    if (
      request.path === '/auth/register' ||
      request.path === '/auth/login' ||
      request.path === '/health' ||
      (request.method === 'GET' && request.path === '/settings')
    ) {
      return true;
    }
    const header = request.headers.authorization;
    const token = header?.startsWith('Bearer ') ? header.slice('Bearer '.length) : undefined;
    if (!token) {
      if (requireAuth()) throw new UnauthorizedException('Bearer token is required.');
      return true;
    }
    try {
      request.user = (await this.jwt.verifyAsync(token, {
        secret: process.env.JWT_SECRET ?? 'workbridge-local-dev-secret'
      })) as { sub: string; email?: string };
      return true;
    } catch {
      throw new UnauthorizedException('Invalid bearer token.');
    }
  }
}
