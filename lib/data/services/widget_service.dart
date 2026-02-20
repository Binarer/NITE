import 'dart:io';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../models/tag_model.dart';
import '../models/task_model.dart';

/// Сервис обновления виджета домашнего экрана (Android App Widget).
/// Передаёт данные ближайшей предстоящей задачи через home_widget.
class WidgetService {
  static const String _appGroupId = 'group.com.example.nite';
  static const String _androidWidgetName = 'NiteWidgetProvider';

  static final WidgetService _instance = WidgetService._internal();
  factory WidgetService() => _instance;
  WidgetService._internal();

  /// Инициализация (вызывается один раз в main)
  Future<void> init() async {
    if (!Platform.isAndroid) return;
    await HomeWidget.setAppGroupId(_appGroupId);
    await HomeWidget.registerBackgroundCallback(_backgroundCallback);
  }

  /// Обновляет виджет данными ближайшей предстоящей задачи.
  /// [tasks] — список всех задач (текущий и будущие дни).
  /// [allTags] — все теги для получения эмодзи.
  Future<void> updateWithNextTask(
    List<TaskModel> tasks,
    List<TagModel> allTags,
  ) async {
    if (!Platform.isAndroid) return;

    final now = DateTime.now();

    // Ищем ближайшую невыполненную задачу с сегодня и вперёд
    final upcoming = tasks
        .where((t) => !t.isCompleted)
        .where((t) {
          final taskDay = DateTime(t.date.year, t.date.month, t.date.day);
          final today = DateTime(now.year, now.month, now.day);
          if (taskDay.isBefore(today)) return false;
          // Если сегодня — проверяем время
          if (taskDay == today && t.startMinutes != null) {
            final taskMinutes = t.startMinutes!;
            final nowMinutes = now.hour * 60 + now.minute;
            return taskMinutes >= nowMinutes;
          }
          return true;
        })
        .toList()
      ..sort((a, b) {
        // Сначала по дате, потом по времени начала
        final dateComp = a.date.compareTo(b.date);
        if (dateComp != 0) return dateComp;
        final aMin = a.startMinutes ?? 9999;
        final bMin = b.startMinutes ?? 9999;
        return aMin.compareTo(bMin);
      });

    if (upcoming.isEmpty) {
      await _clearWidget();
      return;
    }

    final task = upcoming.first;

    // Эмодзи первого тега задачи
    String tagEmoji = '📋';
    if (task.tagIds.isNotEmpty) {
      final tag = allTags.firstWhere(
        (t) => t.id == task.tagIds.first,
        orElse: () => TagModel(
          id: '',
          name: '',
          emoji: '📋',
          colorValue: 0xFF555555,
        ),
      );
      tagEmoji = tag.emoji.isNotEmpty ? tag.emoji : '📋';
    }

    // Цвет приоритета
    final priorityColor = _priorityToColor(task.priority);

    // Форматирование времени
    String timeStr = '';
    if (task.startMinutes != null) {
      final h = task.startMinutes! ~/ 60;
      final m = task.startMinutes! % 60;
      timeStr = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
      if (task.endMinutes != null) {
        final eh = task.endMinutes! ~/ 60;
        final em = task.endMinutes! % 60;
        timeStr +=
            ' – ${eh.toString().padLeft(2, '0')}:${em.toString().padLeft(2, '0')}';
      }
    }

    // Форматирование даты
    final today = DateTime(now.year, now.month, now.day);
    final taskDay =
        DateTime(task.date.year, task.date.month, task.date.day);
    String dateStr;
    if (taskDay == today) {
      dateStr = 'Сегодня';
    } else if (taskDay == today.add(const Duration(days: 1))) {
      dateStr = 'Завтра';
    } else {
      dateStr = DateFormat('d MMM', 'ru').format(task.date);
    }

    // Сохраняем данные в SharedPreferences для нативного виджета
    await HomeWidget.saveWidgetData('widget_task_name', task.name);
    await HomeWidget.saveWidgetData('widget_task_time', timeStr);
    await HomeWidget.saveWidgetData('widget_task_date', dateStr);
    await HomeWidget.saveWidgetData('widget_tag_emoji', tagEmoji);
    await HomeWidget.saveWidgetData('widget_priority_color', priorityColor);

    // Триггерим обновление нативного виджета
    await HomeWidget.updateWidget(
      androidName: _androidWidgetName,
    );
  }

  /// Сбрасывает виджет (нет задач)
  Future<void> _clearWidget() async {
    await HomeWidget.saveWidgetData<String>('widget_task_name', null);
    await HomeWidget.saveWidgetData<String>('widget_task_time', null);
    await HomeWidget.saveWidgetData<String>('widget_task_date', null);
    await HomeWidget.saveWidgetData('widget_tag_emoji', '📋');
    await HomeWidget.saveWidgetData('widget_priority_color', '#555555');
    await HomeWidget.updateWidget(androidName: _androidWidgetName);
  }

  /// Конвертирует приоритет (0–5) в hex-цвет
  String _priorityToColor(int priority) {
    switch (priority) {
      case 0:
        return '#555555';
      case 1:
        return '#7B8B6F'; // приглушённый зелёный
      case 2:
        return '#4A90D9'; // синий
      case 3:
        return '#F5A623'; // оранжевый
      case 4:
        return '#E8534A'; // красный
      case 5:
        return '#C0392B'; // тёмно-красный (максимум)
      default:
        return '#555555';
    }
  }
}

/// Фоновый callback (вызывается системой при тапе по виджету)
@pragma('vm:entry-point')
Future<void> _backgroundCallback(Uri? uri) async {
  // Можно обработать deep link если нужно
}
