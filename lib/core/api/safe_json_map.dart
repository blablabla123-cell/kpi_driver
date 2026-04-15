/// Безопасное приведение ответа API к `Map<String, dynamic>` без исключений на «чужих» Map.
Map<String, dynamic>? asStringKeyMap(Object? value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    try {
      return value.map(
        (k, v) => MapEntry(k.toString(), v),
      ).cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }
  return null;
}
