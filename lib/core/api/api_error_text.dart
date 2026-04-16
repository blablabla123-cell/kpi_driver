import 'safe_json_map.dart';

/// KPI-DRIVE: ошибки в `MESSAGES.error` (массив строк или одна строка).
String? extractKpiMessagesError(Object? body) {
  final m = asStringKeyMap(body is Map ? body : null);
  if (m == null) return null;
  final messages = asStringKeyMap(m['MESSAGES']) ?? asStringKeyMap(m['messages']);
  if (messages == null) return null;
  final err = messages['error'];
  if (err == null) return null;
  if (err is List) {
    final parts = err
        .map((e) => e?.toString().trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return null;
    return parts.join('\n');
  }
  final s = err.toString().trim();
  return s.isEmpty ? null : s;
}

/// Текст для пользователя из JSON-тела ответа при HTTP-ошибках (4xx/5xx и т.п.).
/// Сначала KPI `MESSAGES`, затем распространённые поля `message` / `error` / `error_message`.
String? extractHttpBodyErrorText(Object? body) {
  final fromMessages = extractKpiMessagesError(body);
  if (fromMessages != null) return fromMessages;

  final m = asStringKeyMap(body is Map ? body : null);
  if (m == null) return null;
  final msg = m['message'] ?? m['error_message'];
  if (msg != null && msg.toString().trim().isNotEmpty) {
    return msg.toString().trim();
  }
  final err = m['error'];
  if (err != null && err is! List) {
    final s = err.toString().trim();
    if (s.isNotEmpty) return s;
  }
  return null;
}
