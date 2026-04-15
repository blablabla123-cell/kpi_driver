import 'dart:ui' show PointerDeviceKind;

import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/board_column.dart';
import '../../domain/entities/task_item.dart';
import '../card_density.dart';
import '../cubit/board_cubit.dart';
import '../task_card_ui_status.dart';
import 'task_card_tile.dart';

/// Канбан на [drag_and_drop_lists]: горизонтальные колонки, карточки между колонками и внутри.
class KanbanDragBoard extends StatefulWidget {
  const KanbanDragBoard({
    super.key,
    required this.columns,
    required this.taskUiById,
    required this.onTaskTap,
    this.cardDensity = CardDensity.comfortable,
    this.dragEnabled = true,
  });

  final List<BoardColumn> columns;
  final Map<int, TaskCardUiStatus> taskUiById;
  final void Function(TaskItem task) onTaskTap;
  final CardDensity cardDensity;
  final bool dragEnabled;

  static const double listWidth = 300;

  @override
  State<KanbanDragBoard> createState() => _KanbanDragBoardState();
}

class _KanbanDragBoardState extends State<KanbanDragBoard> {
  late final ScrollController _horizontalScrollController;

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final compact = widget.cardDensity == CardDensity.compact;

    final children = <DragAndDropList>[
      for (final column in widget.columns) _buildList(context, column, compact),
    ];

    final board = DragAndDropLists(
      scrollController: _horizontalScrollController,
      axis: Axis.horizontal,
      listWidth: KanbanDragBoard.listWidth,
      listDivider: const SizedBox(width: 12),
      listDividerOnLastChild: false,
      listPadding: EdgeInsets.zero,
      removeTopPadding: true,
      constrainDraggingAxis: false,
      itemDragOnLongPress: true,
      itemSizeAnimationDurationMilliseconds: 220,
      itemGhostOpacity: 0.35,
      itemDivider: SizedBox(height: compact ? 6 : 8),
      lastItemTargetHeight: 32,
      lastListTargetSize: 56,
      itemDraggingWidth: KanbanDragBoard.listWidth - 28,
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
      itemGhost: _ItemGhostPlaceholder(
        color: scheme.surfaceContainerHigh,
        height: compact ? 56 : 72,
      ),
      children: children,
      // Не вызывать emit/Bloc при drag — иначе пересоздаются [DragAndDropItem],
      // пакет ищет перетаскиваемый элемент по ссылке (==) и [onItemReorder] не срабатывает.
      onItemDraggingChanged: (item, dragging) {
        if (dragging) {
          HapticFeedback.selectionClick();
        }
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

    // Горизонтальный скролл колонок: полоса прокрутки + на десктопе — drag мышью
    // (по умолчанию у [ListView] он отключён).
    return ScrollConfiguration(
      behavior: _KanbanDragBoardScrollBehavior(),
      child: Scrollbar(
        controller: _horizontalScrollController,
        thumbVisibility: true,
        trackVisibility: true,
        interactive: true,
        child: board,
      ),
    );
  }

  DragAndDropList _buildList(
    BuildContext context,
    BoardColumn column,
    bool compact,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final headerRow = Row(
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

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          child: Material(
            color: scheme.surfaceContainerHigh.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: headerRow,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Divider(
          height: 1,
          thickness: 1,
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ],
    );

    final items = <DragAndDropItem>[
      for (final task in column.tasks)
        DragAndDropItem(
          key: ValueKey<int>(task.indicatorToMoId),
          canDrag: widget.dragEnabled &&
              (widget.taskUiById[task.indicatorToMoId] ??
                      TaskCardUiStatus.idle) !=
                  TaskCardUiStatus.saving,
          feedbackWidget: _DragFeedback(
            task: task,
            taskUiById: widget.taskUiById,
            density: widget.cardDensity,
          ),
          child: TaskCardTile(
            task: task,
            density: widget.cardDensity,
            status: widget.taskUiById[task.indicatorToMoId] ??
                TaskCardUiStatus.idle,
            onTap: () => widget.onTaskTap(task),
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
        padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
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

/// Разрешает перетаскивать горизонтальный [ListView] колонок мышью (macOS/Windows/Linux).
class _KanbanDragBoardScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.mouse,
      };
}

class _DragFeedback extends StatelessWidget {
  const _DragFeedback({
    required this.task,
    required this.taskUiById,
    required this.density,
  });

  final TaskItem task;
  final Map<int, TaskCardUiStatus> taskUiById;
  final CardDensity density;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1.03,
      child: Material(
        color: Colors.transparent,
        child: TaskCardTile(
          task: task,
          density: density,
          status:
              taskUiById[task.indicatorToMoId] ?? TaskCardUiStatus.dragging,
        ),
      ),
    );
  }
}

class _ItemGhostPlaceholder extends StatelessWidget {
  const _ItemGhostPlaceholder({required this.color, required this.height});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
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
