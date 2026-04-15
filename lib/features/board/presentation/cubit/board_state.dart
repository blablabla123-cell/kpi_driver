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
    required this.snackNonce,
    required this.snackMessage,
    required this.snackShowUndo,
  });

  factory BoardState.initial() => const BoardState(
        status: BoardLoadStatus.initial,
        columns: [],
        errorMessage: null,
        taskUiById: {},
        snackNonce: 0,
        snackMessage: null,
        snackShowUndo: false,
      );

  final BoardLoadStatus status;
  final List<BoardColumn> columns;
  final String? errorMessage;
  final Map<int, TaskCardUiStatus> taskUiById;

  /// Монотонно растёт, чтобы [BlocListener] мог показать SnackBar без лишних дублей.
  final int snackNonce;
  final String? snackMessage;
  final bool snackShowUndo;

  bool get isBoardEmpty =>
      status == BoardLoadStatus.success && columns.every((c) => c.tasks.isEmpty);

  BoardState copyWith({
    BoardLoadStatus? status,
    List<BoardColumn>? columns,
    String? errorMessage,
    bool clearErrorMessage = false,
    Map<int, TaskCardUiStatus>? taskUiById,
    int? snackNonce,
    String? snackMessage,
    bool clearSnackMessage = false,
    bool? snackShowUndo,
  }) {
    return BoardState(
      status: status ?? this.status,
      columns: columns ?? this.columns,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      taskUiById: taskUiById ?? this.taskUiById,
      snackNonce: snackNonce ?? this.snackNonce,
      snackMessage:
          clearSnackMessage ? null : (snackMessage ?? this.snackMessage),
      snackShowUndo: clearSnackMessage ? false : (snackShowUndo ?? this.snackShowUndo),
    );
  }

  @override
  List<Object?> get props =>
      [status, columns, errorMessage, taskUiById, snackNonce, snackMessage, snackShowUndo];
}
