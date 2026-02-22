import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/AppConstants/app_constants.dart';
import '../../models/AiReportModel/ai_report_model.dart';
import '../../models/FoodItemModel/food_item_model.dart';
import '../../models/MealPlanModel/meal_plan_model.dart';
import '../../models/ScenarioModel/scenario_model.dart';
import '../../models/SubtaskModel/subtask_model.dart';
import '../../models/TagModel/tag_model.dart';
import '../../models/TaskModel/task_model.dart';
import '../../repositories/AiReportRepository/ai_report_repository.dart';
import '../../repositories/TaskRepository/task_repository.dart';
import '../ReportService/report_service.dart';
import '../SettingsService/settings_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

// ─── Имена задач ─────────────────────────────────────────────────────────────

const String kDailyReportTask = 'nite_daily_report';
const String kWeeklyReportTask = 'nite_weekly_report';

// ─── Top-level callback — ОБЯЗАН быть top-level функцией ─────────────────────

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      // Инициализируем Flutter-движок
      WidgetsFlutterBinding.ensureInitialized();

      // Инициализируем Hive
      final appDocDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocDir.path);

      // Регистрируем адаптеры (безопасно повторно)
      if (!Hive.isAdapterRegistered(TagModelAdapter().typeId)) {
        Hive.registerAdapter(TagModelAdapter());
      }
      if (!Hive.isAdapterRegistered(SubtaskModelAdapter().typeId)) {
        Hive.registerAdapter(SubtaskModelAdapter());
      }
      if (!Hive.isAdapterRegistered(TaskModelAdapter().typeId)) {
        Hive.registerAdapter(TaskModelAdapter());
      }
      if (!Hive.isAdapterRegistered(MacroNutrientsAdapter().typeId)) {
        Hive.registerAdapter(MacroNutrientsAdapter());
      }
      if (!Hive.isAdapterRegistered(FoodItemModelAdapter().typeId)) {
        Hive.registerAdapter(FoodItemModelAdapter());
      }
      if (!Hive.isAdapterRegistered(ScenarioTaskAdapter().typeId)) {
        Hive.registerAdapter(ScenarioTaskAdapter());
      }
      if (!Hive.isAdapterRegistered(ScenarioModelAdapter().typeId)) {
        Hive.registerAdapter(ScenarioModelAdapter());
      }
      if (!Hive.isAdapterRegistered(AiReportModelAdapter().typeId)) {
        Hive.registerAdapter(AiReportModelAdapter());
      }
      if (!Hive.isAdapterRegistered(MealEntryAdapter().typeId)) {
        Hive.registerAdapter(MealEntryAdapter());
      }
      if (!Hive.isAdapterRegistered(MealPlanModelAdapter().typeId)) {
        Hive.registerAdapter(MealPlanModelAdapter());
      }

      // Открываем только нужные боксы
      if (!Hive.isBoxOpen(AppConstants.settingsBox)) {
        await Hive.openBox(AppConstants.settingsBox);
      }
      if (!Hive.isBoxOpen(AppConstants.tasksBox)) {
        await Hive.openBox<TaskModel>(AppConstants.tasksBox);
      }
      if (!Hive.isBoxOpen(AppConstants.reportsBox)) {
        await Hive.openBox<AiReportModel>(AppConstants.reportsBox);
      }

      // Регистрируем зависимости в GetX (если не зарегистрированы)
      if (!Get.isRegistered<SettingsService>()) {
        Get.put(SettingsService(), permanent: true);
      }
      if (!Get.isRegistered<TaskRepository>()) {
        Get.put(TaskRepository(), permanent: true);
      }
      if (!Get.isRegistered<AiReportRepository>()) {
        Get.put(AiReportRepository(), permanent: true);
      }

      final settings = Get.find<SettingsService>();

      // Проверяем наличие API-ключа
      final provider = settings.aiProvider;
      final apiKey = settings.getApiKey(provider);
      if (apiKey.isEmpty) return true; // нет ключа — пропускаем

      // Уведомления из WorkManager не поддерживаются awesome_notifications напрямую.
      // Вместо этого генерируем отчёт и выставляем флаг — уведомление покажется
      // при следующем открытии приложения через SplashScreen.

      // Проверяем интернет
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isEmpty || result[0].rawAddress.isEmpty) return true;
      } catch (_) {
        return true;
      }

      if (taskName == kDailyReportTask) {
        await _runDailyReport(settings);
      } else if (taskName == kWeeklyReportTask) {
        await _runWeeklyReport(settings);
      }

      return true;
    } catch (e) {
      // Возвращаем true чтобы workmanager не пытался перезапустить задачу сразу
      return true;
    }
  });
}

// ─── Логика задач ────────────────────────────────────────────────────────────

Future<void> _runDailyReport(SettingsService settings) async {
  if (!settings.notificationsEnabled) return;

  final now = DateTime.now();
  final reportHour = settings.dailyReportHour;
  // Проверяем время: только после заданного часа
  if (now.hour < reportHour) return;

  // Проверяем — был ли уже отчёт за сегодня
  final reportRepo = Get.find<AiReportRepository>();
  final today = DateTime(now.year, now.month, now.day);
  final existing = reportRepo.getDailyReport(today);
  if (existing != null) return;

  final result = await ReportService().generateDailyReport(date: now);
  if (result != null) {
    // Уведомление нельзя показать из фона (awesome_notifications).
    // Выставляем флаг — SplashScreen покажет уведомление при следующем открытии.
    await settings.setPendingDailyReport(true);
  }
}

Future<void> _runWeeklyReport(SettingsService settings) async {
  if (!settings.notificationsEnabled) return;

  // Проверяем — только в понедельник
  final now = DateTime.now();
  if (now.weekday != DateTime.monday) return;

  // Ищем задачи прошлой недели
  final taskRepo = Get.find<TaskRepository>();
  final thisMonday = now.subtract(Duration(days: now.weekday - 1));
  final lastMonday = thisMonday.subtract(const Duration(days: 7));
  final lastSunday = lastMonday.add(const Duration(days: 6));
  final completedTasks = taskRepo.getAll().where((t) {
    final d = DateTime(t.date.year, t.date.month, t.date.day);
    return t.isCompleted &&
        !d.isBefore(DateTime(lastMonday.year, lastMonday.month, lastMonday.day)) &&
        !d.isAfter(DateTime(lastSunday.year, lastSunday.month, lastSunday.day));
  }).toList();

  if (completedTasks.isEmpty) return;

  final result = await ReportService().generateWeeklyReport(weekStart: lastMonday);
  if (result != null) {
    await settings.setPendingWeeklyReport(true);
  }
}

// ─── Регистрация задач ────────────────────────────────────────────────────────

/// Инициализирует Workmanager и регистрирует периодические задачи.
/// Вызывать из main() ПОСЛЕ инициализации Flutter.
Future<void> initBackgroundWorker() async {
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  // Ежедневный отчёт — каждые 6 часов (минимум workmanager = 15 мин,
  // практически срабатывает вечером когда время >= 20:00)
  await Workmanager().registerPeriodicTask(
    kDailyReportTask,
    kDailyReportTask,
    frequency: const Duration(hours: 6),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    existingWorkPolicy: ExistingWorkPolicy.keep,
    backoffPolicy: BackoffPolicy.linear,
    backoffPolicyDelay: const Duration(minutes: 30),
  );

  // Еженедельный отчёт — каждые 12 часов (сработает в понедельник)
  await Workmanager().registerPeriodicTask(
    kWeeklyReportTask,
    kWeeklyReportTask,
    frequency: const Duration(hours: 12),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    existingWorkPolicy: ExistingWorkPolicy.keep,
    backoffPolicy: BackoffPolicy.linear,
    backoffPolicyDelay: const Duration(minutes: 30),
  );
}

/// Отменяет все фоновые задачи (при отключении уведомлений).
Future<void> cancelBackgroundWorker() async {
  await Workmanager().cancelByUniqueName(kDailyReportTask);
  await Workmanager().cancelByUniqueName(kWeeklyReportTask);
}
