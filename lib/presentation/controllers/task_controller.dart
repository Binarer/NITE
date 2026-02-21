import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/subtask_model.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/settings_service.dart';
import '../../core/utils/app_logger.dart';

class TaskController extends GetxController {
  final TaskRepository _repo = Get.find<TaskRepository>();
  final _uuid = const Uuid();

  final RxList<TaskModel> allTasks = <TaskModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadTasks();
  }

  void loadTasks() {
    allTasks.value = _repo.getAll();
  }

  /// Планирует уведомление-напоминание для задачи, если у неё есть время начала
  /// и уведомления включены в настройках.
  Future<void> _scheduleReminderIfNeeded(TaskModel task) async {
    try {
      final settings = Get.find<SettingsService>();
      // Проверяем оба флага: общие уведомления И напоминания о задачах
      if (!settings.notificationsEnabled) return;
      if (!settings.taskRemindersEnabled) return;
      final startMinutes = task.startMinutes;
      if (startMinutes == null) return;
      await NotificationService().scheduleTaskReminder(
        taskId: task.id,
        taskName: task.name,
        date: task.date,
        startMinutes: startMinutes,
        minutesBefore: settings.taskReminderMinutes,
      );
    } catch (e, st) {
      log.error('NotificationService', 'Ошибка планирования: $e\n$st');
    }
  }

  /// Отменяет уведомление-напоминание для задачи
  Future<void> _cancelReminder(String taskId) async {
    try {
      await NotificationService().cancelTaskReminder(taskId);
    } catch (_) {}
  }

  List<TaskModel> getByDate(DateTime date) => _repo.getByDate(date);

  List<TaskModel> getByWeek(DateTime weekStart) => _repo.getByWeek(weekStart);

  Future<void> saveTask(TaskModel task) async {
    await _repo.save(task);
    loadTasks();
    await _scheduleReminderIfNeeded(task);
  }

  Future<TaskModel> createTask({
    required String name,
    String description = '',
    List<String> tagIds = const [],
    int priority = 0,
    bool useAiPriority = false,
    required DateTime date,
    int? startMinutes,
    int? endMinutes,
    String? foodItemId,
    List<String> foodItemIds = const [],
    String? scenarioId,
    List<SubtaskModel> subtasks = const [],
    double foodGrams = 100.0,
  }) async {
    final tasks = getByDate(date);
    final sortOrder = tasks.isEmpty ? 0 : tasks.last.sortOrder + 1;

    final task = TaskModel(
      id: _uuid.v4(),
      name: name,
      description: description,
      tagIds: tagIds,
      priority: priority,
      useAiPriority: useAiPriority,
      date: DateTime(date.year, date.month, date.day),
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      sortOrder: sortOrder,
      foodItemId: foodItemId,
      foodItemIds: foodItemIds,
      scenarioId: scenarioId,
      subtasks: subtasks,
      foodGrams: foodGrams,
    );

    await _repo.save(task);
    loadTasks();
    await _scheduleReminderIfNeeded(task);
    return task;
  }

  Future<void> deleteTask(String id) async {
    await _cancelReminder(id);
    await _repo.delete(id);
    loadTasks();
  }

  Future<void> toggleComplete(TaskModel task) async {
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    await _repo.save(updated);
    loadTasks();
  }

  /// Перемещает задачу на другую дату (drag & drop между днями)
  Future<void> moveTaskToDate(TaskModel task, DateTime newDate) async {
    final tasks = getByDate(newDate);
    final sortOrder = tasks.isEmpty ? 0 : tasks.last.sortOrder + 1;

    final updated = task.copyWith(
      date: DateTime(newDate.year, newDate.month, newDate.day),
      sortOrder: sortOrder,
    );
    await _repo.save(updated);
    loadTasks();
    await _scheduleReminderIfNeeded(updated);
  }

  /// Переключает статус подзадачи.
  /// Если все подзадачи выполнены — автоматически закрывает задачу.
  Future<void> toggleSubtask(TaskModel task, String subtaskId) async {
    final updatedSubtasks = task.subtasks.map((s) {
      if (s.id == subtaskId) {
        return SubtaskModel(id: s.id, title: s.title, isCompleted: !s.isCompleted);
      }
      return s;
    }).toList();

    // Автозакрытие: если все подзадачи выполнены — помечаем задачу как completed
    final allDone = updatedSubtasks.isNotEmpty &&
        updatedSubtasks.every((s) => s.isCompleted);
    final updated = task.copyWith(
      subtasks: updatedSubtasks,
      isCompleted: allDone ? true : task.isCompleted,
    );
    await _repo.save(updated);
    loadTasks();
  }

  /// Переупорядочивает задачи внутри одного дня
  Future<void> reorderTasksInDay(DateTime date, int oldIndex, int newIndex) async {
    final tasks = getByDate(date);
    if (oldIndex < 0 || oldIndex >= tasks.length) return;
    if (newIndex < 0 || newIndex >= tasks.length) return;

    final item = tasks.removeAt(oldIndex);
    tasks.insert(newIndex, item);

    for (int i = 0; i < tasks.length; i++) {
      final updated = tasks[i].copyWith(sortOrder: i);
      await _repo.save(updated);
    }
    loadTasks();
  }
}
