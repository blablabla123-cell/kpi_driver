import '../repositories/indicators_repository.dart';

class SaveTaskField {
  const SaveTaskField(this._repo);

  final IndicatorsRepository _repo;

  Future<void> call({
    required String periodStart,
    required String periodEnd,
    required String periodKey,
    required int indicatorToMoId,
    required int authUserId,
    required String fieldName,
    required String fieldValue,
  }) {
    return _repo.saveTaskField(
      periodStart: periodStart,
      periodEnd: periodEnd,
      periodKey: periodKey,
      indicatorToMoId: indicatorToMoId,
      authUserId: authUserId,
      fieldName: fieldName,
      fieldValue: fieldValue,
    );
  }
}

