import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/AppConstants/app_constants.dart';
import '../../models/DailyMealLogModel/daily_meal_log_model.dart';


class DailyMealLogRepository {
  Box<DailyMealLog> get _box =>
      Hive.box<DailyMealLog>(AppConstants.dailyMealLogBox);

  List<DailyMealLog> getAll() => _box.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  /// Получить запись за конкретный день (по дате без времени)
  DailyMealLog? getByDate(DateTime date) {
    final key = _dateKey(date);
    return _box.values.where((l) => _dateKey(l.date) == key).firstOrNull;
  }

  /// Получить или создать запись за день
  Future<DailyMealLog> getOrCreate(DateTime date) async {
    final existing = getByDate(date);
    if (existing != null) return existing;
    final log = DailyMealLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime(date.year, date.month, date.day),
    );
    await _box.put(log.id, log);
    return log;
  }

  Future<void> save(DailyMealLog log) async {
    await _box.put(log.id, log);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}
