import '../entities/task_item.dart';

abstract interface class IndicatorsRepository {
  Future<List<TaskItem>> fetchTasks({
    required String periodStart,
    required String periodEnd,
    required String periodKey,
    required int requestedMoId,
    required String behaviourKey,
    required bool withResult,
    required String responseFields,
    required int authUserId,
  });

  Future<void> saveTaskField({
    required String periodStart,
    required String periodEnd,
    required String periodKey,
    required int indicatorToMoId,
    required int authUserId,
    required String fieldName,
    required String fieldValue,
  });
}

