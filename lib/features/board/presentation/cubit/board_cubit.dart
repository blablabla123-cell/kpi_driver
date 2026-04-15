import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/default_board_query.dart';
import '../../domain/entities/board_column.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/services/build_board_columns.dart';
import '../../domain/usecases/fetch_tasks.dart';
import '../task_card_ui_status.dart';
import 'board_state.dart';

class BoardCubit extends Cubit<BoardState> {
  BoardCubit(this._fetchTasks) : super(BoardState.initial());

  final FetchTasks _fetchTasks;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: BoardLoadStatus.loading,
        clearErrorMessage: true,
      ),
    );
    try {
      final tasks = await _fetchTasks(
        periodStart: DefaultBoardQuery.periodStart,
        periodEnd: DefaultBoardQuery.periodEnd,
        periodKey: DefaultBoardQuery.periodKey,
        requestedMoId: DefaultBoardQuery.requestedMoId,
        behaviourKey: DefaultBoardQuery.behaviourKey,
        withResult: DefaultBoardQuery.withResult,
        responseFields: DefaultBoardQuery.responseFields,
        authUserId: DefaultBoardQuery.authUserId,
      );
      final columns = buildBoardColumns(tasks);
      emit(
        state.copyWith(
          status: BoardLoadStatus.success,
          columns: columns,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BoardLoadStatus.failure,
          errorMessage: e.toString(),
          columns: const [],
        ),
      );
    }
  }

  /// Локальное перемещение карточки (Шаг 4). Сохранение на сервер — Шаг 5.
  void applyItemReorder({
    required int oldItemIndex,
    required int oldListIndex,
    required int newItemIndex,
    required int newListIndex,
  }) {
    if (state.status != BoardLoadStatus.success) return;

    final columnCount = state.columns.length;
    if (oldListIndex < 0 ||
        oldListIndex >= columnCount ||
        newListIndex < 0 ||
        newListIndex >= columnCount) {
      return;
    }

    final columns = state.columns
        .map(
          (c) => BoardColumn(
            parentId: c.parentId,
            title: c.title,
            tasks: List<TaskItem>.from(c.tasks),
          ),
        )
        .toList();

    final sourceTasks = List<TaskItem>.from(columns[oldListIndex].tasks);
    if (oldItemIndex < 0 || oldItemIndex >= sourceTasks.length) return;

    final moving = sourceTasks.removeAt(oldItemIndex);
    final targetParentId = columns[newListIndex].parentId;
    final updatedTask = moving.copyWith(parentId: targetParentId);

    if (oldListIndex == newListIndex) {
      sourceTasks.insert(newItemIndex, updatedTask);
      columns[oldListIndex] = BoardColumn(
        parentId: columns[oldListIndex].parentId,
        title: columns[oldListIndex].title,
        tasks: _withSequentialOrder(sourceTasks),
      );
    } else {
      columns[oldListIndex] = BoardColumn(
        parentId: columns[oldListIndex].parentId,
        title: columns[oldListIndex].title,
        tasks: _withSequentialOrder(sourceTasks),
      );

      final destTasks = List<TaskItem>.from(columns[newListIndex].tasks);
      destTasks.insert(newItemIndex, updatedTask);
      columns[newListIndex] = BoardColumn(
        parentId: columns[newListIndex].parentId,
        title: columns[newListIndex].title,
        tasks: _withSequentialOrder(destTasks),
      );
    }

    final ui = Map<int, TaskCardUiStatus>.from(state.taskUiById)
      ..remove(updatedTask.indicatorToMoId);

    emit(
      state.copyWith(
        columns: columns,
        taskUiById: ui,
      ),
    );
  }

  void onItemDragChanged(DragAndDropItem item, bool dragging) {
    final id = _taskIdFromKey(item.key);
    if (id == null) return;

    final next = Map<int, TaskCardUiStatus>.from(state.taskUiById);
    if (dragging) {
      next[id] = TaskCardUiStatus.dragging;
    } else {
      next.remove(id);
    }
    emit(state.copyWith(taskUiById: next));
  }

  static List<TaskItem> _withSequentialOrder(List<TaskItem> tasks) {
    return [
      for (var i = 0; i < tasks.length; i++) tasks[i].copyWith(order: i),
    ];
  }

  static int? _taskIdFromKey(Key? key) {
    if (key is ValueKey<int>) return key.value;
    return null;
  }
}
