import { ConflictException, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';

import type { AuthSession, SafeUser } from './domain';
import { StoreService } from './store.service';

@Injectable()
export class AuthService {
  constructor(
    private readonly store: StoreService,
    private readonly jwt: JwtService
  ) {}

  async register(input: { email: string; password: string; fullName?: string }): Promise<AuthSession> {
    const email = input.email.trim().toLowerCase();
    if (!email || !input.password || input.password.length < 8) {
      throw new UnauthorizedException('Email and a password of at least 8 characters are required.');
    }
    if (this.store.findUserByEmail(email)) {
      throw new ConflictException('A user with this email already exists.');
    }
    const passwordHash = await bcrypt.hash(input.password, 12);
    const user = this.store.createUser({
      email,
      passwordHash,
      fullName: input.fullName ?? email
    });
    return this.session(user);
  }

  async login(input: { email: string; password: string }): Promise<AuthSession> {
    const user = this.store.findUserByEmail(input.email);
    if (!user || !user.passwordHash) throw new UnauthorizedException('Invalid email or password.');
    const valid = await bcrypt.compare(input.password, user.passwordHash);
    if (!valid) throw new UnauthorizedException('Invalid email or password.');
    return this.session({
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt
    });
  }

  me(userId: string): SafeUser {
    const user = this.store.findUserById(userId);
    if (!user) throw new UnauthorizedException('User not found.');
    return user;
  }

  private async session(user: SafeUser): Promise<AuthSession> {
    return {
      user,
      accessToken: await this.jwt.signAsync({ sub: user.id, email: user.email })
    };
  }
}
