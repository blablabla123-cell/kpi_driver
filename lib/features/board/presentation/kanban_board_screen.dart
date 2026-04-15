import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/theme_cubit.dart';
import 'cubit/board_cubit.dart';
import 'cubit/board_state.dart';
import 'widgets/board_loading_shimmer.dart';
import 'widgets/kanban_drag_board.dart';

class KanbanBoardScreen extends StatelessWidget {
  const KanbanBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.select((ThemeCubit c) => c.state.themeMode);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Доска'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: () => context.read<BoardCubit>().load(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Тема',
            onPressed: () => context.read<ThemeCubit>().toggleLightDark(),
            icon: Icon(switch (mode) {
              ThemeMode.dark => Icons.dark_mode_outlined,
              _ => Icons.light_mode_outlined,
            }),
          ),
        ],
      ),
      body: BlocBuilder<BoardCubit, BoardState>(
        builder: (context, state) {
          return switch (state.status) {
            BoardLoadStatus.initial => const BoardLoadingShimmer(),
            BoardLoadStatus.loading => const BoardLoadingShimmer(),
            BoardLoadStatus.failure => _BoardError(
                message: state.errorMessage ?? 'Не удалось загрузить задачи',
                onRetry: () => context.read<BoardCubit>().load(),
              ),
            BoardLoadStatus.success => state.isBoardEmpty
                ? _BoardEmpty(onRetry: () => context.read<BoardCubit>().load())
                : Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                    child: KanbanDragBoard(
                      columns: state.columns,
                      taskUiById: state.taskUiById,
                      onTaskTap: (task) {
                        showModalBottomSheet<void>(
                          context: context,
                          showDragHandle: true,
                          builder: (ctx) {
                            final tt = Theme.of(ctx).textTheme;
                            return SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      task.name,
                                      style: tt.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'ID: ${task.indicatorToMoId}',
                                      style: tt.bodyMedium?.copyWith(
                                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    if (task.parentId != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Папка (parent_id): ${task.parentId}',
                                        style: tt.bodySmall?.copyWith(
                                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          };
        },
      ),
    );
  }
}

class _BoardError extends StatelessWidget {
  const _BoardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 56, color: scheme.error),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoardEmpty extends StatelessWidget {
  const _BoardEmpty({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Пока нет задач',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Когда API вернёт задачи, они появятся в колонках.',
              style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Обновить'),
            ),
          ],
        ),
      ),
    );
  }
}
