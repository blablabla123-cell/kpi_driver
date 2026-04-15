import 'package:flutter/foundation.dart';

import '../../../../core/api/safe_json_map.dart';

@immutable
class IndicatorTaskDto {
  const IndicatorTaskDto({
    required this.indicatorToMoId,
    required this.name,
    required this.parentId,
    required this.order,
  });

  final int indicatorToMoId;
  final String name;
  final int? parentId;
  final int? order;

  factory IndicatorTaskDto.fromJson(Map<String, dynamic> json) {
    return IndicatorTaskDto(
      indicatorToMoId: _asInt(json['indicator_to_mo_id']) ?? 0,
      name: (json['name'] ?? '').toString(),
      parentId: _asInt(json['parent_id']),
      order: _asInt(json['order']),
    );
  }

  /// Пропускает элементы с битой структурой/типами.
  static IndicatorTaskDto? tryParse(Object? raw) {
    final map = asStringKeyMap(raw);
    if (map == null) return null;
    final dto = IndicatorTaskDto.fromJson(map);
    if (dto.indicatorToMoId <= 0) return null;
    if (dto.name.trim().isEmpty) return null;
    return dto;
  }

  static int? _asInt(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}

