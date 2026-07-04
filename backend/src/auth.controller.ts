import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import type { Request } from 'express';

import { AuthService } from './auth.service';
import { JwtAuthGuard } from './jwt-auth.guard';
import { DEMO_USER_ID } from './store.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('register')
  register(@Body() input: { email: string; password: string; fullName?: string }) {
    return this.auth.register(input);
  }

  @Post('login')
  login(@Body() input: { email: string; password: string }) {
    return this.auth.login(input);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  me(@Req() req: Request & { user?: { sub: string } }) {
    return this.auth.me(req.user?.sub ?? DEMO_USER_ID);
  }
}
