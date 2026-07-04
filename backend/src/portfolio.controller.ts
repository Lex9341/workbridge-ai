import { Body, Controller, Delete, Get, Param, Post, Put } from '@nestjs/common';

import type { PortfolioProject } from './domain';
import { CurrentUserId } from './current-user';
import { StoreService } from './store.service';

@Controller('portfolio-projects')
export class PortfolioController {
  constructor(private readonly store: StoreService) {}

  @Get()
  list(@CurrentUserId() userId: string): PortfolioProject[] {
    return this.store.listPortfolioProjects(userId);
  }

  @Post()
  create(@Body() input: Omit<PortfolioProject, 'id'>, @CurrentUserId() userId: string): PortfolioProject {
    return this.store.createPortfolioProject(input, userId);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() input: Partial<PortfolioProject>, @CurrentUserId() userId: string): PortfolioProject | undefined {
    return this.store.updatePortfolioProject(id, input, userId);
  }

  @Delete(':id')
  delete(@Param('id') id: string, @CurrentUserId() userId: string) {
    this.store.deletePortfolioProject(id, userId);
    return { deleted: true };
  }
}
