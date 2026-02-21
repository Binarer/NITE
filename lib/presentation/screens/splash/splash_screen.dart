import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/ai_report_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/settings_service.dart';

/// Экран загрузки — показывается при каждом запуске приложения.
/// Перепланирует все уведомления и переходит на главный экран.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  String _status = 'Загрузка...';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final settings = Get.find<SettingsService>();
      final notifications = NotificationService();

      // Шаг 1: убеждаемся что уведомления инициализированы
      _setStatus('Инициализация уведомлений...');
      await notifications.init();
      await notifications.setTimezone(settings.timezone);
      notifications.setActionListener();
      await notifications.requestPermissions();

      // Шаг 2: перепланируем все напоминания о задачах
      // (нужно при каждом запуске — после ребута ОС сбрасывает scheduled notifications)
      if (settings.notificationsEnabled && settings.taskRemindersEnabled) {
        _setStatus('Планирование напоминаний...');
        await notifications.rescheduleAllReminders(settings);
      }

      // Шаг 3: перепланируем системные уведомления (ретроспектива, ежедневный отчёт)
      if (settings.notificationsEnabled) {
        _setStatus('Настройка расписания...');
        await notifications.scheduleWeeklyRetrospective();
        await notifications.scheduleDailyReport();
      }

      // Минимальная задержка для плавного UX
      await Future.delayed(const Duration(milliseconds: 600));
    } catch (e) {
      // Если что-то пошло не так — всё равно переходим на главный экран
    }

    // Переходим на главный экран, убирая splash из стека
    await Get.offAllNamed(AppRoutes.home);

    // Небольшая задержка после перехода — навигатор должен смонтироваться
    await Future.delayed(const Duration(milliseconds: 300));

    final settings = Get.find<SettingsService>();

    // Показываем экран должника если есть просрочки
    _maybeShowDebtor(settings);

    // Показываем диалог ежедневного отчёта (если время >= 20:00)
    await _maybeShowDailyReport(settings);

    // Показываем диалог еженедельной ретроспективы (если сегодня ПН)
    await _maybeShowWeeklyRetrospective(settings);
  }

  void _setStatus(String status) {
    if (mounted) setState(() => _status = status);
  }

  void _maybeShowDebtor(SettingsService settings) {
    if (!settings.debtorEnabled) return;
    try {
      final taskRepo = Get.find<TaskRepository>();
      final today = DateTime.now();
      final todayDay = DateTime(today.year, today.month, today.day);
      final overdue = taskRepo.getAll().where((t) =>
          !t.isCompleted &&
          DateTime(t.date.year, t.date.month, t.date.day)
              .isBefore(todayDay)).toList();
      if (overdue.isNotEmpty && Get.currentRoute == AppRoutes.home) {
        Get.toNamed(AppRoutes.debtor);
      }
    } catch (_) {}
  }

  Future<void> _maybeShowDailyReport(SettingsService settings) async {
    if (!settings.notificationsEnabled) return;
    try {
      final reportRepo = Get.find<AiReportRepository>();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final existing = reportRepo.getDailyReport(today);
      if (existing == null) return;

      // Показываем если: время >= заданного часа ИЛИ WorkManager сгенерировал в фоне
      final shouldShow = now.hour >= settings.dailyReportHour || settings.pendingDailyReport;
      if (!shouldShow) return;
      if (Get.currentRoute != AppRoutes.home) return;

      final wasPending = settings.pendingDailyReport;
      await settings.setPendingDailyReport(false);
      // Показываем push-уведомление если отчёт был сгенерирован в фоне
      if (wasPending) {
        NotificationService().showDailyReportNotification(
          existing.content.length > 100
              ? '${existing.content.substring(0, 100)}...'
              : existing.content,
          today,
        );
      }
      Get.dialog(
        _DailyReportDialog(report: existing.content),
        barrierDismissible: true,
      );
    } catch (_) {}
  }

  Future<void> _maybeShowWeeklyRetrospective(SettingsService settings) async {
    if (!settings.notificationsEnabled) return;
    try {
      final reportRepo = Get.find<AiReportRepository>();
      final now = DateTime.now();
      final thisMonday = now.subtract(Duration(days: now.weekday - 1));
      final lastMonday = thisMonday.subtract(const Duration(days: 7));
      final report = reportRepo.getWeeklyReport(lastMonday);
      if (report == null) return;

      // Показываем если: сегодня ПН ИЛИ WorkManager сгенерировал в фоне
      final shouldShow = now.weekday == DateTime.monday || settings.pendingWeeklyReport;
      if (!shouldShow) return;
      if (Get.currentRoute != AppRoutes.home) return;

      final wasPendingWeekly = settings.pendingWeeklyReport;
      await settings.setPendingWeeklyReport(false);
      if (wasPendingWeekly) {
        NotificationService().showWeeklyReportNotification(
          report.content.length > 100
              ? '${report.content.substring(0, 100)}...'
              : report.content,
        );
      }
      Get.dialog(
        _WeeklyReportDialog(report: report.content),
        barrierDismissible: true,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  Widget _buildBody() {
    return _SplashBody(status: _status, fadeAnim: _fadeAnim, scaleAnim: _scaleAnim);
  }
}

class _SplashBody extends StatelessWidget {
  final String status;
  final Animation<double> fadeAnim;
  final Animation<double> scaleAnim;
  const _SplashBody({required this.status, required this.fadeAnim, required this.scaleAnim});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: fadeAnim,
        child: ScaleTransition(
          scale: scaleAnim,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Лого
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Text(
                      'Ni',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'NiTe',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 48),
                // Индикатор загрузки
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    status,
                    key: ValueKey(status),
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Диалог ежедневного отчёта ────────────────────────────────────────────────

class _DailyReportDialog extends StatelessWidget {
  final String report;
  const _DailyReportDialog({required this.report});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1C1C1C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF3A3A3A)),
      ),
      title: const Row(children: [
        Text('📊', style: TextStyle(fontSize: 20)),
        SizedBox(width: 8),
        Expanded(
          child: Text('Итоги дня',
              style: TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ),
      ]),
      content: SingleChildScrollView(
        child: Text(report,
            style: const TextStyle(
                color: Color(0xFFB0B0B0), fontSize: 14, height: 1.5)),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Закрыть',
              style: TextStyle(color: Color(0xFF888888))),
        ),
      ],
    );
  }
}

// ─── Диалог еженедельного отчёта ─────────────────────────────────────────────

class _WeeklyReportDialog extends StatelessWidget {
  final String report;
  const _WeeklyReportDialog({required this.report});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1C1C1C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF3A3A3A)),
      ),
      title: const Row(children: [
        Text('🤖', style: TextStyle(fontSize: 20)),
        SizedBox(width: 8),
        Expanded(
          child: Text('Итоги недели',
              style: TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ),
      ]),
      content: SingleChildScrollView(
        child: Text(report,
            style: const TextStyle(
                color: Color(0xFFB0B0B0), fontSize: 14, height: 1.5)),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Закрыть',
              style: TextStyle(color: Color(0xFF888888))),
        ),
      ],
    );
  }
}
