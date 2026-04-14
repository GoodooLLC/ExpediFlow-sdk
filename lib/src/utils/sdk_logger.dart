// Логирование событий SDK

import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class SdkLogger {
  static LogLevel _minLevel = LogLevel.info;
  static final List<LogEntry> _history = [];
  static const int _maxHistory = 500;

  // Callback для внешних подписчиков (хост-приложение)
  static void Function(LogEntry entry)? onLog;

  static void setMinLevel(LogLevel level) => _minLevel = level;

  static List<LogEntry> get history => List.unmodifiable(_history);

  static void debug(String message) => _log(LogLevel.debug, message);
  static void info(String message) => _log(LogLevel.info, message);
  static void warning(String message) => _log(LogLevel.warning, message);
  static void error(String message) => _log(LogLevel.error, message);

  static void _log(LogLevel level, String message) {
    if (level.index < _minLevel.index) return;

    final entry = LogEntry(
      level: level,
      message: message,
      timestamp: DateTime.now(),
    );

    _history.add(entry);
    if (_history.length > _maxHistory) {
      _history.removeAt(0);
    }

    debugPrint('[NewCas ${entry.levelTag}] $message');
    onLog?.call(entry);
  }

  static void clear() => _history.clear();
}

class LogEntry {
  final LogLevel level;
  final String message;
  final DateTime timestamp;

  LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
  });

  String get levelTag {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
    }
  }

  @override
  String toString() =>
      '${timestamp.toIso8601String()} [$levelTag] $message';
}
