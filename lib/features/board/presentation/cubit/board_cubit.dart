import 'dart:async';

import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/default_board_query.dart';
import '../../../../core/errors/user_friendly_error.dart';
import '../../domain/entities/board_column.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/services/build_board_columns.dart';
import '../../domain/services/task_parent_id_codec.dart';
import '../../domain/usecases/fetch_tasks.dart';
import '../../domain/usecases/save_task_field.dart';
import '../task_card_ui_status.dart';
import 'board_state.dart';

class BoardCubit extends Cubit<BoardState> {
  BoardCubit(this._fetchTasks, this._saveTaskField) : super(BoardState.initial());

  final FetchTasks _fetchTasks;
  final SaveTaskField _saveTaskField;

  List<BoardColumn>? _undoColumns;
  int? _undoTaskId;

  Future<void> load() async {
    _undoColumns = null;
    _undoTaskId = null;
    emit(
      state.copyWith(
        status: BoardLoadStatus.loading,
        clearErrorMessage: true,
        clearSnackMessage: true,
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
          taskUiById: {},
          clearSnackMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BoardLoadStatus.failure,
          errorMessage: userFriendlyMessage(e),
          columns: const [],
          taskUiById: {},
          clearSnackMessage: true,
        ),
      );
    }
  }

  void consumeSnackBar() {
    if (state.snackMessage == null) return;
    emit(state.copyWith(clearSnackMessage: true));
  }

  Future<void> undoLastSave() async {
    final snap = _undoColumns;
    final taskId = _undoTaskId;
    if (snap == null || taskId == null || state.status != BoardLoadStatus.success) {
      return;
    }

    final revertedTask = _findTask(snap, taskId);
    if (revertedTask == null) return;

    _undoColumns = null;
    _undoTaskId = null;

    final ui = Map<int, TaskCardUiStatus>.from(state.taskUiById)
      ..[taskId] = TaskCardUiStatus.saving;

    emit(state.copyWith(columns: _cloneColumns(snap), taskUiById: ui, clearSnackMessage: true));

    try {
      await _saveParentAndOrder(revertedTask);
      if (isClosed) return;
      final cleared = Map<int, TaskCardUiStatus>.from(state.taskUiById)..remove(taskId);
      emit(
        state.copyWith(
          taskUiById: cleared,
          snackNonce: state.snackNonce + 1,
          snackMessage: 'Изменение отменено',
          snackShowUndo: false,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      final cleared = Map<int, TaskCardUiStatus>.from(state.taskUiById)..remove(taskId);
      emit(
        state.copyWith(
          taskUiById: cleared,
          snackNonce: state.snackNonce + 1,
          snackMessage: 'Не удалось отменить: ${userFriendlyMessage(e)}',
          snackShowUndo: false,
        ),
      );
    }
  }

  /// Локально обновляем доску и сохраняем `parent_id` + `order` (две формы подряд).
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

    final beforeSnapshot = _cloneColumns(state.columns);

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
    if (state.taskUiById[moving.indicatorToMoId] == TaskCardUiStatus.saving) {
      return;
    }

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

    final taskAfter = _findTask(columns, moving.indicatorToMoId);
    if (taskAfter == null) return;

    if (_samePersistedFields(moving, taskAfter)) {
      final ui = Map<int, TaskCardUiStatus>.from(state.taskUiById)..remove(moving.indicatorToMoId);
      emit(state.copyWith(columns: columns, taskUiById: ui));
      return;
    }

    final ui = Map<int, TaskCardUiStatus>.from(state.taskUiById)
      ..remove(moving.indicatorToMoId)
      ..[taskAfter.indicatorToMoId] = TaskCardUiStatus.saving;

    emit(state.copyWith(columns: columns, taskUiById: ui));

    unawaited(
      _persistMove(columnsBefore: beforeSnapshot, taskBeforeMove: moving, taskAfterMove: taskAfter),
    );
  }

  Future<void> _persistMove({
    required List<BoardColumn> columnsBefore,
    required TaskItem taskBeforeMove,
    required TaskItem taskAfterMove,
  }) async {
    final taskId = taskAfterMove.indicatorToMoId;
    try {
      await _saveParentAndOrder(taskAfterMove);
      if (isClosed) return;

      _undoColumns = _cloneColumns(columnsBefore);
      _undoTaskId = taskId;

      final ui = Map<int, TaskCardUiStatus>.from(state.taskUiById)..remove(taskId);

      emit(
        state.copyWith(
          taskUiById: ui,
          snackNonce: state.snackNonce + 1,
          snackMessage: 'Сохранено',
          snackShowUndo: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;

      final ui = Map<int, TaskCardUiStatus>.from(state.taskUiById)
        ..[taskId] = TaskCardUiStatus.error;

      emit(
        state.copyWith(
          columns: _cloneColumns(columnsBefore),
          taskUiById: ui,
          snackNonce: state.snackNonce + 1,
          snackMessage: 'Не удалось сохранить: ${userFriendlyMessage(e)}',
          snackShowUndo: false,
        ),
      );

      _undoColumns = null;
      _undoTaskId = null;

      _scheduleClearTaskError(taskId);
    }
  }

  Future<void> _saveParentAndOrder(TaskItem task) async {
    await _saveTaskField(
      periodStart: DefaultBoardQuery.periodStart,
      periodEnd: DefaultBoardQuery.periodEnd,
      periodKey: DefaultBoardQuery.periodKey,
      indicatorToMoId: task.indicatorToMoId,
      authUserId: DefaultBoardQuery.authUserId,
      fieldName: 'parent_id',
      fieldValue: TaskParentIdCodec.toApiValue(task.parentId),
    );
    await _saveTaskField(
      periodStart: DefaultBoardQuery.periodStart,
      periodEnd: DefaultBoardQuery.periodEnd,
      periodKey: DefaultBoardQuery.periodKey,
      indicatorToMoId: task.indicatorToMoId,
      authUserId: DefaultBoardQuery.authUserId,
      fieldName: 'order',
      fieldValue: (task.order ?? 0).toString(),
    );
  }

  void _scheduleClearTaskError(int taskId) {
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (isClosed) return;
      final ui = Map<int, TaskCardUiStatus>.from(state.taskUiById);
      if (ui[taskId] != TaskCardUiStatus.error) return;
      ui.remove(taskId);
      emit(state.copyWith(taskUiById: ui));
    });
  }

  void onItemDragChanged(DragAndDropItem item, bool dragging) {
    final id = _taskIdFromKey(item.key);
    if (id == null) return;
    if (state.taskUiById[id] == TaskCardUiStatus.saving) return;

    final next = Map<int, TaskCardUiStatus>.from(state.taskUiById);
    if (dragging) {
      next[id] = TaskCardUiStatus.dragging;
    } else {
      next.remove(id);
    }
    emit(state.copyWith(taskUiById: next));
  }

  static bool _samePersistedFields(TaskItem before, TaskItem after) {
    return before.parentId == after.parentId && before.order == after.order;
  }

  static TaskItem? _findTask(List<BoardColumn> cols, int id) {
    for (final c in cols) {
      for (final t in c.tasks) {
        if (t.indicatorToMoId == id) return t;
      }
    }
    return null;
  }

  static List<BoardColumn> _cloneColumns(List<BoardColumn> cols) {
    return [
      for (final c in cols)
        BoardColumn(parentId: c.parentId, title: c.title, tasks: List<TaskItem>.from(c.tasks)),
    ];
  }

  static List<TaskItem> _withSequentialOrder(List<TaskItem> tasks) {
    return [for (var i = 0; i < tasks.length; i++) tasks[i].copyWith(order: i)];
  }

  static int? _taskIdFromKey(Key? key) {
    if (key is ValueKey<int>) return key.value;
    return null;
  }
}
