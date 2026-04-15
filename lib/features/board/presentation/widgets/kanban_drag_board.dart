import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/board_column.dart';
import '../../domain/entities/task_item.dart';
import '../cubit/board_cubit.dart';
import '../task_card_ui_status.dart';
import 'task_card_tile.dart';

/// Канбан на [drag_and_drop_lists]: горизонтальные колонки, карточки между колонками и внутри.
class KanbanDragBoard extends StatelessWidget {
  const KanbanDragBoard({
    super.key,
    required this.columns,
    required this.taskUiById,
    required this.onTaskTap,
  });

  final List<BoardColumn> columns;
  final Map<int, TaskCardUiStatus> taskUiById;
  final void Function(TaskItem task) onTaskTap;

  static const double listWidth = 300;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final children = <DragAndDropList>[
      for (final column in columns) _buildList(context, column),
    ];

    return DragAndDropLists(
      axis: Axis.horizontal,
      listWidth: listWidth,
      listDivider: const SizedBox(width: 12),
      listDividerOnLastChild: false,
      listPadding: EdgeInsets.zero,
      removeTopPadding: true,
      constrainDraggingAxis: false,
      itemDragOnLongPress: true,
      itemSizeAnimationDurationMilliseconds: 220,
      itemGhostOpacity: 0.35,
      itemDivider: const SizedBox(height: 8),
      lastItemTargetHeight: 32,
      lastListTargetSize: 56,
      itemDraggingWidth: listWidth - 28,
      itemDecorationWhileDragging: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      itemGhost: _ItemGhostPlaceholder(color: scheme.surfaceContainerHigh),
      children: children,
      onItemDraggingChanged: (item, dragging) {
        if (dragging) {
          HapticFeedback.selectionClick();
        }
        context.read<BoardCubit>().onItemDragChanged(item, dragging);
      },
      onItemReorder: (oldItemIndex, oldListIndex, newItemIndex, newListIndex) {
        HapticFeedback.mediumImpact();
        context.read<BoardCubit>().applyItemReorder(
              oldItemIndex: oldItemIndex,
              oldListIndex: oldListIndex,
              newItemIndex: newItemIndex,
              newListIndex: newListIndex,
            );
      },
      onListReorder: (_, _) {},
    );
  }

  DragAndDropList _buildList(
    BuildContext context,
    BoardColumn column,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final header = Row(
      children: [
        Expanded(
          child: Text(
            column.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '${column.taskCount}',
            style: textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );

    final items = <DragAndDropItem>[
      for (final task in column.tasks)
        DragAndDropItem(
          key: ValueKey<int>(task.indicatorToMoId),
          canDrag:
              (taskUiById[task.indicatorToMoId] ?? TaskCardUiStatus.idle) !=
                  TaskCardUiStatus.saving,
          feedbackWidget: _DragFeedback(
            task: task,
            taskUiById: taskUiById,
          ),
          child: TaskCardTile(
            task: task,
            status:
                taskUiById[task.indicatorToMoId] ?? TaskCardUiStatus.idle,
            onTap: () => onTaskTap(task),
          ),
        ),
    ];

    return DragAndDropList(
      canDrag: false,
      verticalAlignment: CrossAxisAlignment.stretch,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      header: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: header,
      ),
      contentsWhenEmpty: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Нет задач',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
      children: items,
    );
  }
}

class _DragFeedback extends StatelessWidget {
  const _DragFeedback({
    required this.task,
    required this.taskUiById,
  });

  final TaskItem task;
  final Map<int, TaskCardUiStatus> taskUiById;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1.03,
      child: Material(
        color: Colors.transparent,
        child: TaskCardTile(
          task: task,
          status:
              taskUiById[task.indicatorToMoId] ?? TaskCardUiStatus.dragging,
        ),
      ),
    );
  }
}

class _ItemGhostPlaceholder extends StatelessWidget {
  const _ItemGhostPlaceholder({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(
                alpha: 0.5,
              ),
        ),
      ),
    );
  }
}
