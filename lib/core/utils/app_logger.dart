import 'package:flutter/material.dart' show Color;
import 'package:get/get.dart';

enum LogLevel { info, warning, error, success }

class LogEntry {
  final DateTime time;
  final LogLevel level;
  final String tag;
  final String message;

  LogEntry({
    required this.time,
    required this.level,
    required this.tag,
    required this.message,
  });

  String get levelEmoji {
    switch (level) {
      case LogLevel.info:    return 'ℹ️';
      case LogLevel.warning: return '⚠️';
      case LogLevel.error:   return '❌';
      case LogLevel.success: return '✅';
    }
  }

  Color get levelColor {
    switch (level) {
      case LogLevel.info:    return const Color(0xFF90CAF9);
      case LogLevel.warning: return const Color(0xFFFFCC80);
      case LogLevel.error:   return const Color(0xFFEF9A9A);
      case LogLevel.success: return const Color(0xFFA5D6A7);
    }
  }

  String get timeLabel {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

/// Глобальный логгер приложения. Хранит до [maxEntries] записей в памяти.
/// Использует GetX-реактивность — подписывайтесь на [entries] для real-time UI.
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  static const int maxEntries = 500;

  final RxList<LogEntry> entries = <LogEntry>[].obs;

  void _add(LogLevel level, String tag, String message) {
    final entry = LogEntry(
      time: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
    );
    entries.add(entry);
    if (entries.length > maxEntries) {
      entries.removeAt(0);
    }
    // Также выводим в консоль для дебаггинга
    // ignore: avoid_print
    print('[${entry.timeLabel}][${level.name.toUpperCase()}][$tag] $message');
  }

  void info(String tag, String message) => _add(LogLevel.info, tag, message);
  void warning(String tag, String message) => _add(LogLevel.warning, tag, message);
  void error(String tag, String message) => _add(LogLevel.error, tag, message);
  void success(String tag, String message) => _add(LogLevel.success, tag, message);

  void clear() => entries.clear();
}

/// Глобальный экземпляр для удобного доступа
final log = AppLogger();
