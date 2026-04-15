import '../entities/task_item.dart';
import '../repositories/indicators_repository.dart';

class FetchTasks {
  const FetchTasks(this._repo);

  final IndicatorsRepository _repo;

  Future<List<TaskItem>> call({
    required String periodStart,
    required String periodEnd,
    required String periodKey,
    required int requestedMoId,
    required String behaviourKey,
    required bool withResult,
    required String responseFields,
    required int authUserId,
  }) {
    return _repo.fetchTasks(
      periodStart: periodStart,
      periodEnd: periodEnd,
      periodKey: periodKey,
      requestedMoId: requestedMoId,
      behaviourKey: behaviourKey,
      withResult: withResult,
      responseFields: responseFields,
      authUserId: authUserId,
    );
  }
}

