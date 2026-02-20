import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Notification IDs
  static const int _weeklyRetroId = 1;
  static const int _weeklyReportShowId = 2;
  static const int _dailyReportScheduleId = 3;
  static const int _dailyReportShowId = 4;
  static const int _testNotificationId = 99;
  // Task reminders используют ID = 1000 + хэш от task id (по модулю 10000)
  static const int _taskReminderBaseId = 1000;

  Future<void> init() async {
    if (_initialized) return;

    // Инициализация timezone — по умолчанию Екатеринбург (GMT+5)
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Yekaterinburg'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    // Запросить разрешения на Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Устанавливает часовой пояс для уведомлений
  Future<void> setTimezone(String timezone) async {
    try {
      tz.setLocalLocation(tz.getLocation(timezone));
    } catch (_) {
      // Если пояс не найден — оставляем системный
    }
  }

  /// Запланировать еженедельную ретроспективу (каждый ПН в 12:00 по local tz)
  Future<void> scheduleWeeklyRetrospective() async {
    // Отменяем предыдущее расписание
    await _plugin.cancel(1);

    const androidDetails = AndroidNotificationDetails(
      'weekly_retro',
      'Еженедельная ретроспектива',
      channelDescription: 'Еженедельный отчёт о продуктивности от NiTe',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      1,
      'NiTe — Еженедельный отчёт',
      'Ваша недельная статистика готова. Откройте приложение, чтобы посмотреть.',
      _nextMondayAt12(),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Отменить еженедельное расписание
  Future<void> cancelWeeklyRetrospective() async {
    await _plugin.cancel(1);
  }

  /// Показать немедленное уведомление (для ретроспективы)
  Future<void> showRetrospectiveNotification(String summary) async {
    const androidDetails = AndroidNotificationDetails(
      'weekly_retro',
      'Еженедельная ретроспектива',
      channelDescription: 'Еженедельный отчёт о продуктивности от NiTe',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      2,
      'NiTe — Еженедельный отчёт',
      summary,
      details,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ─── Ежедневный отчёт (22:00 каждый день) ────────────────────────────────

  /// Планирует ежедневное уведомление-триггер в 22:00
  Future<void> scheduleDailyReport() async {
    await _plugin.cancel(_dailyReportScheduleId);

    const androidDetails = AndroidNotificationDetails(
      'daily_report',
      'Ежедневный отчёт',
      channelDescription: 'Итоги дня от NiTe AI',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      _dailyReportScheduleId,
      'NiTe — Итоги дня',
      'Подводим итоги... Откройте приложение для отчёта.',
      _nextTimeAt(22, 0),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Отменяет ежедневный отчёт
  Future<void> cancelDailyReport() async {
    await _plugin.cancel(_dailyReportScheduleId);
  }

  /// Показывает мгновенное уведомление с текстом ежедневного отчёта
  Future<void> showDailyReportNotification(String summary, DateTime date) async {
    const androidDetails = AndroidNotificationDetails(
      'daily_report',
      'Ежедневный отчёт',
      channelDescription: 'Итоги дня от NiTe AI',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      _dailyReportShowId,
      'NiTe — Итоги дня',
      summary,
      details,
    );
  }

  /// Показывает мгновенное уведомление с текстом еженедельного отчёта
  Future<void> showWeeklyReportNotification(String summary) async {
    const androidDetails = AndroidNotificationDetails(
      'weekly_retro',
      'Еженедельная ретроспектива',
      channelDescription: 'Еженедельный отчёт о продуктивности от NiTe',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      _weeklyReportShowId,
      'NiTe — Итоги недели',
      summary,
      details,
    );
  }

  // ─── Напоминания о конкретных задачах ────────────────────────────────────

  /// Планирует напоминание о задаче за [minutesBefore] минут до startMinutes.
  /// [taskId] — уникальный ID задачи, [taskName] — название,
  /// [date] — дата задачи, [startMinutes] — время начала (часы*60+минуты).
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String taskName,
    required DateTime date,
    required int startMinutes,
    required int minutesBefore,
  }) async {
    if (!_initialized) await init();

    // Вычисляем числовой ID из taskId (стабильный хэш, влезающий в int)
    final notifId = _taskReminderBaseId + taskId.hashCode.abs() % 10000;

    // Отменяем предыдущее расписание для этой задачи
    await _plugin.cancel(notifId);

    // Время старта задачи
    final taskStart = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      startMinutes ~/ 60,
      startMinutes % 60,
    );

    // Уведомление за N минут до начала
    final notifyAt = taskStart.subtract(Duration(minutes: minutesBefore));

    // Не планируем уведомление в прошлом
    if (notifyAt.isBefore(tz.TZDateTime.now(tz.local))) return;

    const androidDetails = AndroidNotificationDetails(
      'task_reminder',
      'Напоминания о задачах',
      channelDescription: 'Напоминания о предстоящих задачах',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final minutesLabel = minutesBefore == 1
        ? '1 минуту'
        : '$minutesBefore минут';

    await _plugin.zonedSchedule(
      notifId,
      '⏰ Напоминание',
      'Через $minutesLabel: $taskName',
      notifyAt,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Отменяет напоминание для конкретной задачи по её ID
  Future<void> cancelTaskReminder(String taskId) async {
    final notifId = _taskReminderBaseId + taskId.hashCode.abs() % 10000;
    await _plugin.cancel(notifId);
  }

  // ─── Тестовые уведомления (для раздела "Для разработчиков") ──────────────

  Future<void> sendTestReportNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'daily_report',
      'Ежедневный отчёт',
      channelDescription: 'Итоги дня от NiTe AI',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      _testNotificationId,
      '🧪 Тестовый отчёт',
      'Это тестовое уведомление с отчётом. Всё работает корректно!',
      details,
    );
  }

  Future<void> sendTestReminderNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'task_reminder',
      'Напоминания о задачах',
      channelDescription: 'Напоминания о предстоящих задачах',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      _testNotificationId,
      '⏰ Напоминание о задаче',
      'Тестовое напоминание: "Завершить важный проект" через 30 минут',
      details,
    );
  }

  /// Вычисляет следующий понедельник 12:00 в текущем часовом поясе
  tz.TZDateTime _nextMondayAt12() {
    final now = tz.TZDateTime.now(tz.local);
    // weekday: 1=ПН, 7=ВС
    int daysUntilMonday = DateTime.monday - now.weekday;
    if (daysUntilMonday < 0) daysUntilMonday += 7;

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + daysUntilMonday,
      12,
      0,
    );

    // Если сегодня ПН и уже после 12:00 — планируем на следующий ПН
    if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    return scheduled;
  }

  /// Вычисляет следующее наступление заданного времени (hour:minute) каждый день
  tz.TZDateTime _nextTimeAt(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
