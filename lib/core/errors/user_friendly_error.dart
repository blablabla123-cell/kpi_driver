import 'package:dio/dio.dart';

import '../api/api_error_text.dart';

/// Короткое сообщение для UI / SnackBar (русский), без простыни из Dio.
String userFriendlyMessage(Object error) {
  if (error is DioException) {
    return _dioMessage(error);
  }
  if (error is FormatException) {
    final m = error.message;
    if (m.isNotEmpty) return m;
  }

  final s = error.toString();
  const prefix = 'FormatException: ';
  if (s.startsWith(prefix)) {
    return s.substring(prefix.length);
  }
  const ex = 'Exception: ';
  if (s.startsWith(ex)) {
    return s.substring(ex.length);
  }
  return _truncate(s, 180);
}

String _dioMessage(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Превышено время ожидания. Проверьте сеть и попробуйте снова.';
    case DioExceptionType.connectionError:
      return 'Нет соединения с сервером. Проверьте интернет (и CORS для Web).';
    case DioExceptionType.badCertificate:
      return 'Ошибка защищённого соединения (сертификат).';
    case DioExceptionType.badResponse:
      final code = e.response?.statusCode;
      final body = e.response?.data;
      final fromBody = extractHttpBodyErrorText(body);
      if (fromBody != null && fromBody.isNotEmpty) {
        return _truncate(fromBody, 180);
      }
      if (code == 401 || code == 403) {
        return 'Доступ запрещён (401/403). Проверьте токен и права.';
      }
      if (code != null && code >= 500) {
        return 'Сервер временно недоступен ($code). Попробуйте позже.';
      }
      if (code != null) {
        return 'Ошибка сервера (код $code).';
      }
      return 'Некорректный ответ сервера.';
    case DioExceptionType.cancel:
      return 'Запрос отменён.';
    case DioExceptionType.unknown:
      if (e.error != null) {
        return _truncate(e.error.toString(), 180);
      }
      return 'Неизвестная сетевая ошибка.';
  }
}

String _truncate(String s, int max) {
  final t = s.trim();
  if (t.length <= max) return t;
  return '${t.substring(0, max)}…';
}
