/// Defaults from the test task / IMPLEMENTATION_PLAN — single place to change for demo.
class DefaultBoardQuery {
  const DefaultBoardQuery._();

  static const String periodStart = '2026-04-01';
  static const String periodEnd = '2026-04-30';
  static const String periodKey = 'month';
  static const int requestedMoId = 42;
  static const String behaviourKey = 'task,kpi_task';
  static const bool withResult = false;
  static const String responseFields = 'name,indicator_to_mo_id,parent_id,order';
  static const int authUserId = 40;
}
