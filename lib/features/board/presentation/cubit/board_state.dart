import 'package:equatable/equatable.dart';

import '../../domain/entities/board_column.dart';
import '../task_card_ui_status.dart';

enum BoardLoadStatus { initial, loading, success, failure }

class BoardState extends Equatable {
  const BoardState({
    required this.status,
    required this.columns,
    required this.errorMessage,
    required this.taskUiById,
  });

  factory BoardState.initial() => const BoardState(
        status: BoardLoadStatus.initial,
        columns: [],
        errorMessage: null,
        taskUiById: {},
      );

  final BoardLoadStatus status;
  final List<BoardColumn> columns;
  final String? errorMessage;
  final Map<int, TaskCardUiStatus> taskUiById;

  bool get isBoardEmpty =>
      status == BoardLoadStatus.success && columns.every((c) => c.tasks.isEmpty);

  BoardState copyWith({
    BoardLoadStatus? status,
    List<BoardColumn>? columns,
    String? errorMessage,
    bool clearErrorMessage = false,
    Map<int, TaskCardUiStatus>? taskUiById,
  }) {
    return BoardState(
      status: status ?? this.status,
      columns: columns ?? this.columns,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      taskUiById: taskUiById ?? this.taskUiById,
    );
  }

  @override
  List<Object?> get props => [status, columns, errorMessage, taskUiById];
}
