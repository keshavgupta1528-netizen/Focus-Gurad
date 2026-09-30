import 'package:flutter/services.dart';

/// Bridge to the native Kotlin engine (foreground service + later the blocker).
class EngineChannel {
  static const _c = MethodChannel('focusguard/engine');

  static Future<void> start(int endMillis, int totalMillis) =>
      _c.invokeMethod('startFocus', {'end': endMillis, 'total': totalMillis});

  static Future<void> stop() => _c.invokeMethod('stopFocus');

  /// Returns {end, total} in epoch/duration millis, or an empty map if idle.
  static Future<Map<String, int>> status() async {
    final m = await _c.invokeMapMethod<String, int>('getStatus');
    return m ?? <String, int>{};
  }
}
