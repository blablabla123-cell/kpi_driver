import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/safe_json_map.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/repositories/indicators_repository.dart';
import '../dto/indicator_task_dto.dart';
import '../mappers/indicator_task_mapper.dart';

class IndicatorsRepositoryImpl implements IndicatorsRepository {
  IndicatorsRepositoryImpl(this._api);

  final ApiClient _api;

  static bool _isHttpOk(int? code) => code != null && code >= 200 && code < 300;

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
      options: Options(responseType: ResponseType.json),
    );

    if (!_isHttpOk(res.statusCode)) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
      );
    }

    final body = asStringKeyMap(res.data);
    if (body == null && res.data != null) {
      throw const FormatException('Сервер вернул ответ не в формате JSON-объекта.');
    }

    final list = _extractItemsList(body);
    final out = <TaskItem>[];
    for (final raw in list) {
      final dto = IndicatorTaskDto.tryParse(raw);
      if (dto != null) {
        out.add(dto.toDomain());
      }
    }
    return List<TaskItem>.unmodifiable(out);
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
    final res = await _api.postFormData<Map<String, dynamic>>(
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

    if (!_isHttpOk(res.statusCode)) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
      );
    }
    _throwIfPayloadIndicatesFailure(res.data);
  }

  static void _throwIfPayloadIndicatesFailure(Object? data) {
    final m = asStringKeyMap(data is Map ? data : null);
    if (m == null) return;
    final ok = m['success'];
    if (ok is bool && ok == false) {
      final msg = m['message'] ?? m['error'] ?? m['error_message'];
      throw FormatException(
        (msg != null && msg.toString().trim().isNotEmpty)
            ? msg.toString()
            : 'Сервер отклонил сохранение.',
      );
    }
  }

  static List<Object?> _extractItemsList(Map<String, dynamic>? body) {
    if (body == null) return const [];

    // Реальный ответ KPI-DRIVE: { "DATA": { "rows": [ {...}, ... ] } } (ключ DATA в верхнем регистре).
    final dataUpper = asStringKeyMap(body['DATA']);
    if (dataUpper != null) {
      final rows = dataUpper['rows'];
      if (rows is List) {
        return rows;
      }
    }

    final data = body['data'];
    if (data is List) {
      return data;
    }

    if (data is Map) {
      final dataMap = asStringKeyMap(data);
      final items = dataMap?['items'];
      if (items is List) {
        return items;
      }
      final rows = dataMap?['rows'];
      if (rows is List) {
        return rows;
      }
    }

    final result = body['result'];
    if (result is List) {
      return result;
    }

    return const [];
  }
}
