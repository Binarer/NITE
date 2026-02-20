import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';
import '../../core/constants/app_constants.dart';

class TaskRepository {
  Box<TaskModel> get _box => Hive.box<TaskModel>(AppConstants.tasksBox);

  List<TaskModel> getAll() => _box.values.toList();

  TaskModel? getById(String id) {
    try {
      return _box.values.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Возвращает задачи для конкретной даты
  List<TaskModel> getByDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return _box.values
        .where((t) {
          final taskDay = DateTime(t.date.year, t.date.month, t.date.day);
          return taskDay == day;
        })
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Возвращает задачи за неделю (с Monday по Sunday)
  List<TaskModel> getByWeek(DateTime weekStart) {
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final end = start.add(const Duration(days: 7));
    return _box.values
        .where((t) {
          final day = DateTime(t.date.year, t.date.month, t.date.day);
          return !day.isBefore(start) && day.isBefore(end);
        })
        .toList()
      ..sort((a, b) {
          final dateCompare = a.date.compareTo(b.date);
          if (dateCompare != 0) return dateCompare;
          return a.sortOrder.compareTo(b.sortOrder);
        });
  }

  Future<void> save(TaskModel task) async {
    await _box.put(task.id, task);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> deleteAll(List<String> ids) async {
    await _box.deleteAll(ids);
  }
}
