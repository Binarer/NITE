import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

import 'core/constants/AppConstants/app_constants.dart';
import 'core/routes/AppRoutes/app_routes.dart';
import 'core/theme/AppTheme/app_theme.dart';
import 'data/models/AiReportModel/ai_report_model.dart';
import 'data/models/DailyMealLogModel/daily_meal_log_model.dart';
import 'data/models/FoodItemModel/food_item_model.dart';
import 'data/models/MealPlanModel/meal_plan_model.dart';
import 'data/models/ScenarioModel/scenario_model.dart';
import 'data/models/SubtaskModel/subtask_model.dart';
import 'data/models/TagModel/tag_model.dart';
import 'data/models/TaskModel/task_model.dart';
import 'data/repositories/AiReportRepository/ai_report_repository.dart';
import 'data/repositories/DailyMealLogRepository/daily_meal_log_repository.dart';
import 'data/repositories/FoodItemRepository/food_item_repository.dart';
import 'data/repositories/MealPlanRepository/meal_plan_repository.dart';
import 'data/repositories/ScenarioRepository/scenario_repository.dart';
import 'data/repositories/TagRepository/tag_repository.dart';
import 'data/repositories/TaskRepository/task_repository.dart';
import 'data/services/BackgroundWorker/background_worker.dart';
import 'data/services/ExportImportService/export_import_service.dart';
import 'data/services/SettingsService/settings_service.dart';
import 'presentation/controllers/FoodItemController/food_item_controller.dart';
import 'presentation/controllers/HomeController/home_controller.dart';
import 'presentation/controllers/MealPlanController/meal_plan_controller.dart';
import 'presentation/controllers/ScenarioController/scenario_controller.dart';
import 'presentation/controllers/SettingsController/settings_controller.dart';
import 'presentation/controllers/StatisticsController/statistics_controller.dart';
import 'presentation/controllers/TagController/tag_controller.dart';
import 'presentation/controllers/TaskController/task_controller.dart';
import 'presentation/controllers/TaskFormController/task_form_controller.dart';
import 'presentation/screens/debtor/DebtorScreen/debtor_screen.dart';
import 'presentation/screens/food/FoodDetailScreen/food_detail_screen.dart';
import 'presentation/screens/food/FoodFormScreen/food_form_screen.dart';
import 'presentation/screens/food/FoodLibraryScreen/food_library_screen.dart';
import 'presentation/screens/help/HelpScreen/help_screen.dart';
import 'presentation/screens/home/HomeScreen/home_screen.dart';
import 'presentation/screens/meal_plan/MealPlanScreen/meal_plan_screen.dart';
import 'presentation/screens/reports/ReportsScreen/reports_screen.dart';
import 'presentation/screens/scenario/ScenarioFormScreen/scenario_form_screen.dart';
import 'presentation/screens/scenario/ScenarioListScreen/scenario_list_screen.dart';
import 'presentation/screens/settings/LogsScreen/logs_screen.dart';
import 'presentation/screens/settings/SettingsScreen/settings_screen.dart';
import 'presentation/screens/settings/TagManagerScreen/tag_manager_screen.dart';
import 'presentation/screens/splash/SplashScreen/splash_screen.dart';
import 'presentation/screens/statistics/StatisticsScreen/statistics_screen.dart';
import 'presentation/screens/task/TaskDetailScreen/task_detail_screen.dart';
import 'presentation/screens/task/TaskFormScreen/task_form_screen.dart';

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
  Hive.registerAdapter(MealEntryAdapter());
  Hive.registerAdapter(MealPlanModelAdapter());
  Hive.registerAdapter(DailyMealLogAdapter());

  // Открытие боксов
  await Hive.openBox<TagModel>(AppConstants.tagsBox);
  await Hive.openBox<TaskModel>(AppConstants.tasksBox);
  await Hive.openBox<FoodItemModel>(AppConstants.foodItemsBox);
  await Hive.openBox<ScenarioModel>(AppConstants.scenariosBox);
  await Hive.openBox(AppConstants.settingsBox);
  await Hive.openBox<AiReportModel>(AppConstants.reportsBox);
  await Hive.openBox<MealPlanModel>(AppConstants.mealPlansBox);
  await Hive.openBox<DailyMealLog>(AppConstants.dailyMealLogBox);

  // Регистрация сервисов и репозиториев в GetX (permanent — живут всё время)
  Get.put(SettingsService(), permanent: true);
  Get.put(TagRepository(), permanent: true);
  Get.put(TaskRepository(), permanent: true);
  Get.put(FoodItemRepository(), permanent: true);
  Get.put(ScenarioRepository(), permanent: true);
  Get.put(AiReportRepository(), permanent: true);
  Get.put(MealPlanRepository(), permanent: true);
  Get.put(DailyMealLogRepository(), permanent: true);

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
  Get.put(MealPlanController(), permanent: true);
  Get.put(ExportImportService(), permanent: true);

  // Инициализация фоновых задач (генерация AI-отчётов даже при закрытом приложении)
  // Workmanager поддерживается только на Android и iOS
  final settingsService = Get.find<SettingsService>();
  if (settingsService.notificationsEnabled && (Platform.isAndroid || Platform.isIOS)) {
    await initBackgroundWorker();
  }

  // Уведомления, перепланирование и показ диалогов теперь происходят в SplashScreen
  runApp(const NiteApp());
}

class _TaskFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(TaskFormController());
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
      initialRoute: AppRoutes.splash,
      getPages: [
        GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
        GetPage(name: AppRoutes.home, page: () => const HomeScreen()),
        GetPage(name: AppRoutes.settings, page: () => const SettingsScreen()),
        GetPage(
          name: AppRoutes.taskCreate,
          page: () => const TaskFormScreen(),
          binding: _TaskFormBinding(),
        ),
        GetPage(
          name: AppRoutes.taskDetail,
          page: () => const TaskDetailScreen(),
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
        GetPage(
          name: AppRoutes.mealPlan,
          page: () => const MealPlanScreen(),
        ),
        GetPage(
          name: AppRoutes.debtor,
          page: () => const DebtorScreen(),
        ),
        GetPage(
          name: AppRoutes.logs,
          page: () => const LogsScreen(),
        ),
      ],
    );
  }
}
