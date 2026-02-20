import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

import 'core/constants/app_constants.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'data/models/ai_report_model.dart';
import 'data/models/food_item_model.dart';
import 'data/models/scenario_model.dart';
import 'data/models/subtask_model.dart';
import 'data/models/tag_model.dart';
import 'data/models/task_model.dart';
import 'data/repositories/ai_report_repository.dart';
import 'data/repositories/food_item_repository.dart';
import 'data/repositories/scenario_repository.dart';
import 'data/repositories/tag_repository.dart';
import 'data/repositories/task_repository.dart';
import 'data/services/mistral_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/report_service.dart';
import 'data/services/settings_service.dart';
import 'data/services/widget_service.dart';
import 'presentation/controllers/home_controller.dart';
import 'presentation/controllers/tag_controller.dart';
import 'presentation/controllers/task_controller.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/controllers/food_item_controller.dart';
import 'presentation/controllers/scenario_controller.dart';
import 'presentation/controllers/settings_controller.dart';
import 'presentation/controllers/task_form_controller.dart';
import 'presentation/screens/food/food_detail_screen.dart';
import 'presentation/screens/food/food_form_screen.dart';
import 'presentation/screens/food/food_library_screen.dart';
import 'presentation/screens/scenario/scenario_form_screen.dart';
import 'presentation/screens/scenario/scenario_list_screen.dart';
import 'presentation/controllers/statistics_controller.dart';
import 'presentation/screens/help/help_screen.dart';
import 'presentation/screens/reports/reports_screen.dart';
import 'presentation/screens/settings/tag_manager_screen.dart';
import 'presentation/screens/statistics/statistics_screen.dart';
import 'presentation/screens/task/task_form_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация локализации
  await initializeDateFormatting('ru', null);

  // Инициализация Hive
  final appDocDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocDir.path);

  // Регистрация адаптеров
  Hive.registerAdapter(TagModelAdapter());
  Hive.registerAdapter(SubtaskModelAdapter());
  Hive.registerAdapter(TaskModelAdapter());
  Hive.registerAdapter(MacroNutrientsAdapter());
  Hive.registerAdapter(FoodItemModelAdapter());
  Hive.registerAdapter(ScenarioTaskAdapter());
  Hive.registerAdapter(ScenarioModelAdapter());
  Hive.registerAdapter(AiReportModelAdapter());

  // Открытие боксов
  await Hive.openBox<TagModel>(AppConstants.tagsBox);
  await Hive.openBox<TaskModel>(AppConstants.tasksBox);
  await Hive.openBox<FoodItemModel>(AppConstants.foodItemsBox);
  await Hive.openBox<ScenarioModel>(AppConstants.scenariosBox);
  await Hive.openBox(AppConstants.settingsBox);
  await Hive.openBox<AiReportModel>(AppConstants.reportsBox);

  // Регистрация сервисов и репозиториев в GetX (permanent — живут всё время)
  Get.put(SettingsService(), permanent: true);
  Get.put(TagRepository(), permanent: true);
  Get.put(TaskRepository(), permanent: true);
  Get.put(FoodItemRepository(), permanent: true);
  Get.put(ScenarioRepository(), permanent: true);
  Get.put(AiReportRepository(), permanent: true);

  // Инициализация тегов по умолчанию
  await Get.find<TagRepository>().initDefaultTags();

  // Регистрация контроллеров
  Get.put(TagController(), permanent: true);
  Get.put(TaskController(), permanent: true);
  Get.put(HomeController(), permanent: true);
  Get.put(FoodItemController(), permanent: true);
  Get.put(ScenarioController(), permanent: true);
  Get.put(SettingsController(), permanent: true);
  Get.put(StatisticsController(), permanent: true);

  // Инициализация уведомлений
  final notificationService = NotificationService();
  await notificationService.init();

  // Применяем сохранённый часовой пояс
  final settingsService = Get.find<SettingsService>();
  await notificationService.setTimezone(settingsService.timezone);

  // Если уведомления включены — перепланируем расписание
  if (settingsService.notificationsEnabled) {
    await notificationService.scheduleWeeklyRetrospective();
    await notificationService.scheduleDailyReport();
  }

  // Инициализация виджета домашнего экрана
  await WidgetService().init();

  // Триггер ретроспективы: если сегодня ПН и есть API ключ — показать отчёт
  _maybeShowWeeklyRetrospective(settingsService, notificationService);

  runApp(const NiteApp());
}

class _TaskFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(TaskFormController());
  }
}

/// Проверяет: если сегодня понедельник и уведомления включены —
/// запускает AI-ретроспективу и показывает уведомление + диалог в приложении.
void _maybeShowWeeklyRetrospective(
  SettingsService settings,
  NotificationService notifications,
) async {
  if (!settings.notificationsEnabled) return;
  if (DateTime.now().weekday != DateTime.monday) return;

  final apiKey = settings.mistralApiKey;
  if (apiKey.isEmpty) return;

  // Проверяем интернет
  try {
    final result = await InternetAddress.lookup('api.mistral.ai');
    if (result.isEmpty || result[0].rawAddress.isEmpty) return;
  } catch (_) {
    return;
  }

  // Собираем выполненные задачи прошлой недели
  final repo = Get.find<TaskRepository>();
  final now = DateTime.now();
  final lastMonday = now.subtract(Duration(days: now.weekday - 1 + 7));
  final lastSunday = lastMonday.add(const Duration(days: 6));
  final completedTasks = repo.getAll().where((t) {
    return t.isCompleted &&
        !t.date.isBefore(DateTime(lastMonday.year, lastMonday.month, lastMonday.day)) &&
        !t.date.isAfter(DateTime(lastSunday.year, lastSunday.month, lastSunday.day));
  }).toList();

  if (completedTasks.isEmpty) return;

  try {
    final service = MistralService(apiKey: apiKey);
    final report = await service.generateWeeklyRetrospective(completedTasks);

    // Push-уведомление (краткое)
    final shortSummary = report.length > 120 ? '${report.substring(0, 120)}...' : report;
    await notifications.showRetrospectiveNotification(shortSummary);

    // Диалог внутри приложения (развёрнутый отчёт) — показываем после запуска
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.dialog(
        _WeeklyReportDialog(report: report),
        barrierDismissible: true,
      );
    });
  } catch (_) {
    // Тихо игнорируем ошибки ретроспективы — не мешаем запуску приложения
  }
}

/// Диалог с развёрнутым еженедельным отчётом от AI
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
      title: const Row(
        children: [
          Text('🤖', style: TextStyle(fontSize: 20)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Итоги недели',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Text(
          report,
          style: const TextStyle(
            color: Color(0xFFB0B0B0),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text(
            'Закрыть',
            style: TextStyle(color: Color(0xFF888888)),
          ),
        ),
      ],
    );
  }
}

class NiteApp extends StatelessWidget {
  const NiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'NiTe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      locale: const Locale('ru', 'RU'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru', 'RU')],
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 280),
      initialRoute: AppRoutes.home,
      getPages: [
        GetPage(name: AppRoutes.home, page: () => const HomeScreen()),
        GetPage(name: AppRoutes.settings, page: () => const SettingsScreen()),
        GetPage(
          name: AppRoutes.taskCreate,
          page: () => const TaskFormScreen(),
          binding: _TaskFormBinding(),
        ),
        GetPage(
          name: AppRoutes.taskEdit,
          page: () => const TaskFormScreen(),
          binding: _TaskFormBinding(),
        ),
        GetPage(
          name: AppRoutes.foodLibrary,
          page: () => const FoodLibraryScreen(),
        ),
        GetPage(
          name: AppRoutes.foodCreate,
          page: () => const FoodFormScreen(),
        ),
        GetPage(
          name: AppRoutes.foodDetail,
          page: () => const FoodDetailScreen(),
        ),
        GetPage(
          name: AppRoutes.scenarios,
          page: () => const ScenarioListScreen(),
        ),
        GetPage(
          name: AppRoutes.scenarioCreate,
          page: () => const ScenarioFormScreen(),
        ),
        GetPage(
          name: AppRoutes.tagManager,
          page: () => const TagManagerScreen(),
        ),
        GetPage(
          name: AppRoutes.statistics,
          page: () => const StatisticsScreen(),
        ),
        GetPage(
          name: AppRoutes.reports,
          page: () => const ReportsScreen(),
        ),
        GetPage(
          name: AppRoutes.help,
          page: () => const HelpScreen(),
        ),
      ],
    );
  }
}
