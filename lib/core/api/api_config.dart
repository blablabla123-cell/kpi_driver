import 'package:flutter/foundation.dart';

@immutable
class ApiConfig {
  const ApiConfig({
    required this.baseUrl,
    required this.bearerToken,
  });

  final String baseUrl;
  final String bearerToken;

  /// Defaults copied from the test task spec.
  /// Keep this in one place so it can be swapped later (env/flavors/etc.).
  static const ApiConfig dev = ApiConfig(
    baseUrl: 'https://api.dev.kpi-drive.ru',
    bearerToken: 'Bearer 5c3964b8e3ee4755f2cc0febb851e2f8',
  );
}

