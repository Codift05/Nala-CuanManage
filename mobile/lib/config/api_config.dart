import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  static const _configuredUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_configuredUrl.isNotEmpty) {
      return _configuredUrl;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3001/api';
    }

    return 'http://127.0.0.1:3001/api';
  }
}
