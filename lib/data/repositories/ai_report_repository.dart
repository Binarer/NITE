import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/ai_report_model.dart';
import '../../core/constants/app_constants.dart';

class AiReportRepository {
  Box<AiReportModel> get _box =>
      Hive.box<AiReportModel>(AppConstants.reportsBox);

  final _uuid = const Uuid();

  List<AiReportModel> getAll() =>
      _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));

  List<AiReportModel> getDaily() => getAll()
      .where((r) => r.type == 'daily')
      .toList();

  List<AiReportModel> getWeekly() => getAll()
      .where((r) => r.type == 'weekly')
      .toList();

  /// Сохраняет дневной отчёт (один на день — заменяет предыдущий)
  Future<AiReportModel> saveDailyReport({
    required DateTime date,
    required String content,
  }) async {
    final day = DateTime(date.year, date.month, date.day);
    // Удаляем старый за тот же день
    final old = _box.values.where((r) =>
        r.type == 'daily' &&
        r.date.year == day.year &&
        r.date.month == day.month &&
        r.date.day == day.day);
    for (final r in old.toList()) {
      await _box.delete(r.id);
    }
    final report = AiReportModel(
      id: _uuid.v4(),
      type: 'daily',
      date: day,
      content: content,
      createdAt: DateTime.now(),
    );
    await _box.put(report.id, report);
    return report;
  }

  /// Сохраняет недельный отчёт (один на неделю — заменяет предыдущий)
  Future<AiReportModel> saveWeeklyReport({
    required DateTime weekStart,
    required String content,
  }) async {
    final day = DateTime(weekStart.year, weekStart.month, weekStart.day);
    // Удаляем старый за ту же неделю
    final old = _box.values.where((r) =>
        r.type == 'weekly' &&
        r.date.year == day.year &&
        r.date.month == day.month &&
        r.date.day == day.day);
    for (final r in old.toList()) {
      await _box.delete(r.id);
    }
    final report = AiReportModel(
      id: _uuid.v4(),
      type: 'weekly',
      date: day,
      content: content,
      createdAt: DateTime.now(),
    );
    await _box.put(report.id, report);
    return report;
  }

  /// Возвращает дневной отчёт за конкретный день (или null если нет)
  AiReportModel? getDailyReport(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    try {
      return _box.values.firstWhere((r) =>
          r.type == 'daily' &&
          r.date.year == day.year &&
          r.date.month == day.month &&
          r.date.day == day.day);
    } catch (_) {
      return null;
    }
  }

  /// Возвращает недельный отчёт за неделю начиная с [weekStart] (или null если нет)
  AiReportModel? getWeeklyReport(DateTime weekStart) {
    final day = DateTime(weekStart.year, weekStart.month, weekStart.day);
    try {
      return _box.values.firstWhere((r) =>
          r.type == 'weekly' &&
          r.date.year == day.year &&
          r.date.month == day.month &&
          r.date.day == day.day);
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
