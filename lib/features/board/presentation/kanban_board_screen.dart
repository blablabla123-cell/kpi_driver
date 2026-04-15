import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/theme_cubit.dart';
import '../domain/entities/task_item.dart';
import 'cubit/board_cubit.dart';
import 'cubit/board_state.dart';
import 'cubit/board_view_cubit.dart';
import 'cubit/board_view_state.dart';
import 'utils/filter_board_columns.dart';
import 'widgets/board_chrome_toolbar.dart';
import 'widgets/board_loading_shimmer.dart';
import 'widgets/kanban_drag_board.dart';

class KanbanBoardScreen extends StatelessWidget {
  const KanbanBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<BoardCubit, BoardState>(
      listenWhen: (prev, curr) =>
          curr.snackNonce != prev.snackNonce && curr.snackMessage != null,
      listener: (context, state) {
        final message = state.snackMessage;
        if (message == null) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(message),
            action: state.snackShowUndo
                ? SnackBarAction(
                    label: 'Отменить',
                    onPressed: () {
                      context.read<BoardCubit>().undoLastSave();
                    },
                  )
                : null,
          ),
        );
        context.read<BoardCubit>().consumeSnackBar();
      },
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<BoardCubit, BoardState>(
            buildWhen: (p, c) =>
                p.status != c.status ||
                p.columns != c.columns ||
                p.errorMessage != c.errorMessage,
            builder: (context, boardState) {
              return BlocBuilder<BoardViewCubit, BoardViewState>(
                builder: (context, viewState) {
                  final scheme = Theme.of(context).colorScheme;
                  final tt = Theme.of(context).textTheme;

                  if (boardState.status != BoardLoadStatus.success ||
                      boardState.isBoardEmpty) {
                    return Text('Доска', style: tt.titleLarge);
                  }

                  final totalTasks = countTasks(boardState.columns);
                  final colCount = boardState.columns.length;
                  final filtered =
                      filterBoardColumns(boardState.columns, viewState.searchQuery);
                  final shownTasks = countTasks(filtered);

                  final subtitle = viewState.isSearchActive
                      ? 'Показано $shownTasks из $totalTasks · ${filtered.length} кол.'
                      : '$totalTasks задач · $colCount колонок';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Доска', style: tt.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: tt.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          actions: [
            IconButton(
              tooltip: 'Обновить',
              onPressed: () => context.read<BoardCubit>().load(),
              icon: const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              tooltip: 'Тема',
              onPressed: () => context.read<ThemeCubit>().toggleLightDark(),
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
              ),
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
                  : BlocBuilder<BoardViewCubit, BoardViewState>(
                      builder: (context, viewState) {
                        final filtered = filterBoardColumns(
                          state.columns,
                          viewState.searchQuery,
                        );
                        final searchActive = viewState.isSearchActive;

                        if (searchActive && filtered.isEmpty) {
                          return _NoSearchMatches(
                            onClear: () => context.read<BoardViewCubit>().clearSearch(),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                                child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const BoardSearchField(),
                                  const SizedBox(height: 10),
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: BoardDensityToggle(),
                                  ),
                                  if (searchActive) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Перетаскивание временно отключено, пока активен поиск.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                                child: KanbanDragBoard(
                                  columns: searchActive ? filtered : state.columns,
                                  taskUiById: state.taskUiById,
                                  cardDensity: viewState.cardDensity,
                                  dragEnabled: !searchActive,
                                  onTaskTap: (task) => _openTaskPreview(context, task),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            };
          },
        ),
      ),
    );
  }

  static void _openTaskPreview(BuildContext context, TaskItem task) {
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
  }
}

class _NoSearchMatches extends StatelessWidget {
  const _NoSearchMatches({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 56, color: scheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                'Ничего не найдено',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Попробуйте другой запрос или сбросьте поиск.',
                style: tt.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Сбросить поиск'),
              ),
            ],
          ),
        ),
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
