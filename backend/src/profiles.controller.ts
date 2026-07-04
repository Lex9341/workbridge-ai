import { Body, Controller, Get, Put } from '@nestjs/common';

import type { UserProfile } from './domain';
import { CurrentUserId } from './current-user';
import { StoreService } from './store.service';

@Controller('profile')
export class ProfilesController {
  constructor(private readonly store: StoreService) {}

  @Get()
  getProfile(@CurrentUserId() userId: string): UserProfile {
    return this.store.getProfile(userId);
  }

  @Put()
  updateProfile(@Body() input: Partial<UserProfile>, @CurrentUserId() userId: string): UserProfile {
    return this.store.updateProfile(input, userId);
  }

  @Get('demo')
  getDemoProfile(@CurrentUserId() userId: string): UserProfile {
    return this.store.getProfile(userId);
  }

  @Put('demo')
  updateDemoProfile(@Body() input: Partial<UserProfile>, @CurrentUserId() userId: string): UserProfile {
    return this.store.updateProfile(input, userId);
  }
}
