import { Body, Controller, Delete, Get, Param, Post, Put } from '@nestjs/common';

import type { Credential } from './domain';
import { CurrentUserId } from './current-user';
import { StoreService } from './store.service';

@Controller('credentials')
export class CredentialsController {
  constructor(private readonly store: StoreService) {}

  @Get()
  list(@CurrentUserId() userId: string): Credential[] {
    return this.store.listCredentials(userId);
  }

  @Post()
  create(@Body() input: Omit<Credential, 'id'>, @CurrentUserId() userId: string): Credential {
    return this.store.createCredential(input, userId);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() input: Partial<Credential>, @CurrentUserId() userId: string): Credential | undefined {
    return this.store.updateCredential(id, input, userId);
  }

  @Delete(':id')
  delete(@Param('id') id: string, @CurrentUserId() userId: string) {
    this.store.deleteCredential(id, userId);
    return { deleted: true };
  }
}
