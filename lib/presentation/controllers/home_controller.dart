import 'package:get/get.dart';
import '../../data/models/tag_model.dart';
import '../../data/models/task_model.dart';
import 'tag_controller.dart';
import 'task_controller.dart';

enum ViewMode { week, day }

/// Профиль — «Все» или конкретный тег (фильтр всего экрана)
class ProfileMode {
  static const String all = 'all';
}

class HomeController extends GetxController {
  final TaskController taskController = Get.find<TaskController>();
  final TagController tagController = Get.find<TagController>();

  /// Начало текущей отображаемой недели (Понедельник)
  final Rx<DateTime> currentWeekStart = _getMonday(DateTime.now()).obs;

  /// Режим просмотра: неделя или день
  final Rx<ViewMode> viewMode = ViewMode.week.obs;

  /// Выбранный день (для режима "День")
  final Rx<DateTime> selectedDay = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  ).obs;

  /// Выбранный тег для фильтрации (null = все)
  final RxnString selectedFilterTagId = RxnString();

  /// Активный профиль: null = «Все», иначе tagId
  final RxnString activeProfileTagId = RxnString();

  static DateTime _getMonday(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  /// Список дат текущей недели (ПН–ВС)
  List<DateTime> get weekDays {
    return List.generate(7, (i) => currentWeekStart.value.add(Duration(days: i)));
  }

  bool get isCurrentWeek {
    final todayMonday = _getMonday(DateTime.now());
    return currentWeekStart.value == todayMonday;
  }

  void goToPreviousWeek() {
    currentWeekStart.value = currentWeekStart.value.subtract(const Duration(days: 7));
    selectedFilterTagId.value = null; // сбрасываем фильтр
  }

  void goToNextWeek() {
    currentWeekStart.value = currentWeekStart.value.add(const Duration(days: 7));
    selectedFilterTagId.value = null;
  }

  void goToCurrentWeek() {
    currentWeekStart.value = _getMonday(DateTime.now());
  }

  void setViewMode(ViewMode mode) {
    viewMode.value = mode;
    selectedFilterTagId.value = null;
    // Если переключаемся в день — выбираем сегодня или первый день недели
    if (mode == ViewMode.day) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final inWeek = weekDays.any((d) => d == today);
      selectedDay.value = inWeek ? today : weekDays.first;
    }
  }

  void goToPreviousDay() {
    final prev = selectedDay.value.subtract(const Duration(days: 1));
    selectedDay.value = prev;
    // Если вышли за пределы недели — переходим на предыдущую
    if (prev.isBefore(currentWeekStart.value)) {
      currentWeekStart.value = _getMonday(prev);
    }
  }

  void goToNextDay() {
    final next = selectedDay.value.add(const Duration(days: 1));
    selectedDay.value = next;
    final weekEnd = currentWeekStart.value.add(const Duration(days: 6));
    if (next.isAfter(weekEnd)) {
      currentWeekStart.value = _getMonday(next);
    }
  }

  void selectDay(DateTime date) {
    selectedDay.value = date;
  }

  /// Устанавливает активный профиль (null = «Все»)
  void setProfile(String? tagId) {
    activeProfileTagId.value = tagId;
    selectedFilterTagId.value = null; // сбрасываем доп. фильтр при смене профиля
  }

  /// Устанавливает фильтр по тегу (null = сброс)
  void setTagFilter(String? tagId) {
    selectedFilterTagId.value = tagId;
  }

  /// Теги реально присутствующие на текущей неделе
  List<TagModel> get availableTagsForWeek {
    final allTasks = <TaskModel>[];
    for (final day in weekDays) {
      allTasks.addAll(taskController.getByDate(day));
    }
    final tagIds = allTasks.expand((t) => t.tagIds).toSet();
    return tagController.tags.where((t) => tagIds.contains(t.id)).toList();
  }

  /// Теги реально присутствующие в выбранном дне
  List<TagModel> get availableTagsForDay {
    final tasks = taskController.getByDate(selectedDay.value);
    final tagIds = tasks.expand((t) => t.tagIds).toSet();
    return tagController.tags.where((t) => tagIds.contains(t.id)).toList();
  }

  /// Задачи для конкретного дня с учётом профиля и доп. фильтра по тегу
  List<TaskModel> getTasksForDay(DateTime date) {
    var tasks = taskController.getByDate(date);
    // Сначала фильтр профиля
    final profileId = activeProfileTagId.value;
    if (profileId != null) {
      tasks = tasks.where((t) => t.tagIds.contains(profileId)).toList();
    }
    // Затем доп. фильтр по тегу
    final filterId = selectedFilterTagId.value;
    if (filterId != null) {
      tasks = tasks.where((t) => t.tagIds.contains(filterId)).toList();
    }
    return tasks;
  }

  /// Задачи для режима "День" с учётом фильтра
  List<TaskModel> get tasksForSelectedDay => getTasksForDay(selectedDay.value);

  /// Задачи для конкретного дня (устаревший геттер, оставлен для совместимости)
  List getByDate(DateTime date) => taskController.getByDate(date);

  /// Форматирует диапазон недели: "17–23 февр."
  String get weekRangeLabel {
    final start = currentWeekStart.value;
    final end = start.add(const Duration(days: 6));
    final months = [
      '', 'янв', 'февр', 'март', 'апр', 'май', 'июнь',
      'июль', 'авг', 'сент', 'окт', 'нояб', 'дек'
    ];
    if (start.month == end.month) {
      return '${start.day}–${end.day} ${months[start.month]}';
    }
    return '${start.day} ${months[start.month]} – ${end.day} ${months[end.month]}';
  }

  /// Форматирует выбранный день: "Пн, 17 февр."
  String get selectedDayLabel {
    final d = selectedDay.value;
    final weekdayNames = ['', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final months = [
      '', 'янв', 'февр', 'март', 'апр', 'май', 'июнь',
      'июль', 'авг', 'сент', 'окт', 'нояб', 'дек'
    ];
    return '${weekdayNames[d.weekday]}, ${d.day} ${months[d.month]}';
  }
}
