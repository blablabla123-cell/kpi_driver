import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/repositories/indicators_repository.dart';
import '../dto/indicator_task_dto.dart';
import '../mappers/indicator_task_mapper.dart';

class IndicatorsRepositoryImpl implements IndicatorsRepository {
  IndicatorsRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<List<TaskItem>> fetchTasks({
    required String periodStart,
    required String periodEnd,
    required String periodKey,
    required int requestedMoId,
    required String behaviourKey,
    required bool withResult,
    required String responseFields,
    required int authUserId,
  }) async {
    final res = await _api.postFormData<Map<String, dynamic>>(
      ApiEndpoints.getMoIndicators,
      fields: {
        'period_start': periodStart,
        'period_end': periodEnd,
        'period_key': periodKey,
        'requested_mo_id': requestedMoId,
        'behaviour_key': behaviourKey,
        'with_result': withResult,
        'response_fields': responseFields,
        'auth_user_id': authUserId,
      },
      options: Options(
        responseType: ResponseType.json,
      ),
    );

    final body = res.data;
    final list = _extractItemsList(body);
    return list
        .map((e) => IndicatorTaskDto.fromJson(e).toDomain())
        .where((t) => t.indicatorToMoId != 0 && t.name.trim().isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<void> saveTaskField({
    required String periodStart,
    required String periodEnd,
    required String periodKey,
    required int indicatorToMoId,
    required int authUserId,
    required String fieldName,
    required String fieldValue,
  }) async {
    await _api.postFormData<Map<String, dynamic>>(
      ApiEndpoints.saveIndicatorInstanceField,
      fields: {
        'period_start': periodStart,
        'period_end': periodEnd,
        'period_key': periodKey,
        'indicator_to_mo_id': indicatorToMoId,
        'auth_user_id': authUserId,
        'field_name': fieldName,
        'field_value': fieldValue,
      },
      options: Options(responseType: ResponseType.json),
    );
  }

  static List<Map<String, dynamic>> _extractItemsList(
    Map<String, dynamic>? body,
  ) {
    if (body == null) return const [];

    final data = body['data'];
    if (data is List) {
      return data.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }

    // Some APIs return: { data: { items: [...] } }
    if (data is Map) {
      final items = data['items'];
      if (items is List) {
        return items
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }
    }

    // Fallback: maybe the list is directly in body['result'].
    final result = body['result'];
    if (result is List) {
      return result
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }

    return const [];
  }
}

