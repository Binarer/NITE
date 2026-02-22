import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:get/get.dart';
import '../../../core/utils/AppLogger/app_logger.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tzz;
import '../../repositories/TaskRepository/task_repository.dart';

// ─── Notification channel keys ────────────────────────────────────────────────
const _chTask = 'task_reminder';
const _chWeekly = 'weekly_retro';
const _chDaily = 'daily_report';

// ─── Notification IDs ─────────────────────────────────────────────────────────
const _idWeeklyRetro = 1;
const _idWeeklyShow = 2;
const _idDailySchedule = 3;
const _idDailyShow = 4;
const _idTest = 99;

// ─── Action keys ──────────────────────────────────────────────────────────────
const _keyComplete = 'task_complete';
const _keySnooze = 'task_snooze';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;
  String _timezone = 'Asia/Yekaterinburg';

  // Exposed for background handler
  static const String actionComplete = _keyComplete;

  // ─── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    await AwesomeNotifications().initialize(
      null, // null = use default app icon
      [
        NotificationChannel(
          channelKey: _chTask,
          channelName: 'Напоминания о задачах',
          channelDescription: 'Напоминания о предстоящих задачах',
          importance: NotificationImportance.High,
          defaultRingtoneType: DefaultRingtoneType.Notification,
          locked: false,
          channelShowBadge: true,
        ),
        NotificationChannel(
          channelKey: _chWeekly,
          channelName: 'Еженедельная ретроспектива',
          channelDescription: 'Еженедельный отчёт о продуктивности от NiTe',
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
        NotificationChannel(
          channelKey: _chDaily,
          channelName: 'Ежедневный отчёт',
          channelDescription: 'Итоги дня от NiTe AI',
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
      ],
      debug: false,
    );

    _initialized = true;
    log.success('NotificationService', 'Инициализирован');
  }

  // ─── Permissions ───────────────────────────────────────────────────────────

  Future<bool> requestPermissions() async {
    final allowed = await AwesomeNotifications().isNotificationAllowed();
    if (!allowed) {
      return await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    return true;
  }

  // ─── Timezone ──────────────────────────────────────────────────────────────

  Future<void> setTimezone(String timezone) async {
    try {
      tzz.setLocalLocation(tzz.getLocation(timezone));
      _timezone = timezone;
    } catch (_) {
      try {
        tzz.setLocalLocation(tzz.getLocation('Asia/Yekaterinburg'));
        _timezone = 'Asia/Yekaterinburg';
      } catch (_) {}
    }
  }

  // ─── Action listener ───────────────────────────────────────────────────────

  /// Вызвать один раз в main() или SplashScreen после init()
  void setActionListener() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceived,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _onActionReceived(ReceivedAction action) async {
    final taskId = action.payload?['taskId'];
    if (taskId == null) return;

    if (action.buttonKeyPressed == 'task_open') {
      // ActionType.Default уже поднимает приложение на передний план,
      // дополнительно навигируем на экран задачи
      try {
        Get.toNamed('/task/detail', arguments: taskId);
      } catch (_) {}
    } else if (action.buttonKeyPressed == _keySnooze) {
      // Откладываем на 15 минут
      try {
        final repo = Get.find<TaskRepository>();
        final task = repo.getById(taskId);
        if (task != null) {
          final snoozeAt = DateTime.now().add(const Duration(minutes: 15));
          await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: _notifIdForTask(taskId) + 1,
              channelKey: _chTask,
              title: '⏰ Отложено (+15 мин)',
              body: task.name,
              payload: {'taskId': taskId},
              notificationLayout: NotificationLayout.Default,
            ),
            schedule: NotificationCalendar.fromDate(
              date: snoozeAt,
              allowWhileIdle: true,
              preciseAlarm: true,
            ),
            actionButtons: _taskActionButtons(),
          );
        }
      } catch (_) {}
    }
  }

  // ─── Helper ────────────────────────────────────────────────────────────────

  static int _notifIdForTask(String taskId) {
    var hash = 0;
    for (final c in taskId.codeUnits) {
      hash = (hash * 31 + c) & 0x7FFFFFFF;
    }
    return 1000 + (hash % 9000) + 1;
  }

  static List<NotificationActionButton> _taskActionButtons() => [
        NotificationActionButton(
          key: 'task_open',
          label: '📋 Открыть',
          actionType: ActionType.Default,
          autoDismissible: true,
        ),
        NotificationActionButton(
          key: _keySnooze,
          label: '⏰ +15 мин',
          actionType: ActionType.SilentBackgroundAction,
          autoDismissible: true,
        ),
      ];

  // ─── Task reminders ────────────────────────────────────────────────────────

  Future<void> scheduleTaskReminder({
    required String taskId,
    required String taskName,
    required DateTime date,
    required int startMinutes,
    required int minutesBefore,
  }) async {
    if (!_initialized) await init();

    final notifId = _notifIdForTask(taskId);

    // Отменяем предыдущее
    await AwesomeNotifications().cancel(notifId);

    // Вычисляем время уведомления
    final taskStart = DateTime(
      date.year,
      date.month,
      date.day,
      startMinutes ~/ 60,
      startMinutes % 60,
    );
    final notifyAt = taskStart.subtract(Duration(minutes: minutesBefore));

    if (notifyAt.isBefore(DateTime.now())) {
      log.warning('NotificationService',
          'Напоминание для "$taskName" не запланировано — время в прошлом');
      return;
    }

    final minutesLabel = minutesBefore == 1 ? '1 минуту' : '$minutesBefore минут';

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notifId,
        channelKey: _chTask,
        title: '⏰ Напоминание',
        body: 'Через $minutesLabel: $taskName',
        payload: {'taskId': taskId},
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true,
        category: NotificationCategory.Reminder,
      ),
      schedule: NotificationCalendar(
        year: notifyAt.year,
        month: notifyAt.month,
        day: notifyAt.day,
        hour: notifyAt.hour,
        minute: notifyAt.minute,
        second: 0,
        millisecond: 0,
        allowWhileIdle: true,
        preciseAlarm: true,
        timeZone: _timezone,
      ),
      actionButtons: _taskActionButtons(),
    );

    final h = notifyAt.hour.toString().padLeft(2, '0');
    final m = notifyAt.minute.toString().padLeft(2, '0');
    log.success(
      'NotificationService',
      'Напоминание запланировано: "$taskName" в $h:$m (за $minutesBefore мин до начала)',
    );
  }

  Future<void> cancelTaskReminder(String taskId) async {
    await AwesomeNotifications().cancel(_notifIdForTask(taskId));
  }

  Future<void> rescheduleAllReminders(dynamic settings) async {
    try {
      await setTimezone(settings.timezone as String? ?? 'Asia/Yekaterinburg');

      final taskRepo = Get.find<TaskRepository>();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final minutesBefore = (settings.taskReminderMinutes as int?) ?? 15;

      final futureTasks = taskRepo.getAll().where((t) {
        if (t.startMinutes == null) return false;
        if (t.isCompleted) return false;
        final taskDay = DateTime(t.date.year, t.date.month, t.date.day);
        if (taskDay.isBefore(today)) return false;
        if (taskDay.isAtSameMomentAs(today)) {
          final notifyMinutes = t.startMinutes! - minutesBefore;
          final notifyTime = today.add(Duration(minutes: notifyMinutes));
          if (notifyTime.isBefore(now)) return false;
        }
        return true;
      }).toList();

      int scheduled = 0;
      for (final task in futureTasks) {
        await scheduleTaskReminder(
          taskId: task.id,
          taskName: task.name,
          date: task.date,
          startMinutes: task.startMinutes!,
          minutesBefore: minutesBefore,
        );
        scheduled++;
      }

      if (scheduled > 0) {
        log.success('NotificationService', 'Перепланировано напоминаний: $scheduled');
      }
    } catch (e) {
      log.error('NotificationService', 'Ошибка перепланирования: $e');
    }
  }

  // ─── Weekly retrospective ──────────────────────────────────────────────────

  Future<void> scheduleWeeklyRetrospective() async {
    await AwesomeNotifications().cancel(_idWeeklyRetro);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _idWeeklyRetro,
        channelKey: _chWeekly,
        title: 'NiTe — Еженедельный отчёт',
        body: 'Ваша недельная статистика готова. Откройте приложение.',
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Reminder,
        wakeUpScreen: true,
      ),
      schedule: NotificationCalendar(
        weekday: DateTime.monday,
        hour: 12,
        minute: 0,
        second: 0,
        millisecond: 0,
        repeats: true,
        allowWhileIdle: true,
        timeZone: _timezone,
      ),
    );
    log.success('NotificationService',
        'Еженедельная ретроспектива запланирована (ПН 12:00)');
  }

  Future<void> cancelWeeklyRetrospective() async {
    await AwesomeNotifications().cancel(_idWeeklyRetro);
  }

  Future<void> showRetrospectiveNotification(String summary) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _idWeeklyShow,
        channelKey: _chWeekly,
        title: 'NiTe — Итоги недели',
        body: summary,
        notificationLayout: NotificationLayout.BigText,
      ),
    );
  }

  Future<void> showWeeklyReportNotification(String summary) =>
      showRetrospectiveNotification(summary);

  // ─── Daily report ──────────────────────────────────────────────────────────

  Future<void> scheduleDailyReport() async {
    await AwesomeNotifications().cancel(_idDailySchedule);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _idDailySchedule,
        channelKey: _chDaily,
        title: 'NiTe — Итоги дня',
        body: 'Подводим итоги... Откройте приложение для отчёта.',
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Reminder,
        wakeUpScreen: true,
      ),
      schedule: NotificationCalendar(
        hour: 22,
        minute: 0,
        second: 0,
        millisecond: 0,
        repeats: true,
        allowWhileIdle: true,
        timeZone: _timezone,
      ),
    );
    log.success('NotificationService', 'Ежедневный отчёт запланирован (22:00)');
  }

  Future<void> cancelDailyReport() async {
    await AwesomeNotifications().cancel(_idDailySchedule);
  }

  Future<void> showDailyReportNotification(String summary, DateTime date) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _idDailyShow,
        channelKey: _chDaily,
        title: 'NiTe — Итоги дня',
        body: summary,
        notificationLayout: NotificationLayout.BigText,
      ),
    );
  }

  // ─── Cancel all ────────────────────────────────────────────────────────────

  Future<void> cancelAll() async {
    await AwesomeNotifications().cancelAll();
  }

  // ─── Test notifications ────────────────────────────────────────────────────

  Future<void> sendTestReportNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _idTest,
        channelKey: _chDaily,
        title: '🧪 Тестовый отчёт',
        body: 'Это тестовое уведомление с отчётом. Всё работает корректно!',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  Future<void> sendTestReminderNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _idTest,
        channelKey: _chTask,
        title: '⏰ Напоминание о задаче',
        body: 'Тестовое напоминание: "Завершить важный проект" через 30 минут',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }
}
