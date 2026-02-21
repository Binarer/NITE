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
import 'data/models/meal_plan_model.dart';
import 'data/models/scenario_model.dart';
import 'data/models/subtask_model.dart';
import 'data/models/tag_model.dart';
import 'data/models/task_model.dart';
import 'data/repositories/ai_report_repository.dart';
import 'data/repositories/food_item_repository.dart';
import 'data/repositories/meal_plan_repository.dart';
import 'data/repositories/scenario_repository.dart';
import 'data/repositories/tag_repository.dart';
import 'data/repositories/task_repository.dart';
import 'data/services/background_worker.dart';
import 'data/services/export_import_service.dart';
import 'data/services/settings_service.dart';
import 'presentation/controllers/home_controller.dart';
import 'presentation/screens/splash/splash_screen.dart';
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
import 'presentation/controllers/meal_plan_controller.dart';
import 'presentation/controllers/statistics_controller.dart';
import 'presentation/screens/help/help_screen.dart';
import 'presentation/screens/debtor/debtor_screen.dart';
import 'presentation/screens/meal_plan/meal_plan_screen.dart';
import 'presentation/screens/reports/reports_screen.dart';
import 'presentation/screens/settings/logs_screen.dart';
import 'presentation/screens/settings/tag_manager_screen.dart';
import 'presentation/screens/statistics/statistics_screen.dart';
import 'presentation/screens/task/task_detail_screen.dart';
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
  Hive.registerAdapter(MealEntryAdapter());
  Hive.registerAdapter(MealPlanModelAdapter());

  // Открытие боксов
  await Hive.openBox<TagModel>(AppConstants.tagsBox);
  await Hive.openBox<TaskModel>(AppConstants.tasksBox);
  await Hive.openBox<FoodItemModel>(AppConstants.foodItemsBox);
  await Hive.openBox<ScenarioModel>(AppConstants.scenariosBox);
  await Hive.openBox(AppConstants.settingsBox);
  await Hive.openBox<AiReportModel>(AppConstants.reportsBox);
  await Hive.openBox<MealPlanModel>(AppConstants.mealPlansBox);

  // Регистрация сервисов и репозиториев в GetX (permanent — живут всё время)
  Get.put(SettingsService(), permanent: true);
  Get.put(TagRepository(), permanent: true);
  Get.put(TaskRepository(), permanent: true);
  Get.put(FoodItemRepository(), permanent: true);
  Get.put(ScenarioRepository(), permanent: true);
  Get.put(AiReportRepository(), permanent: true);
  Get.put(MealPlanRepository(), permanent: true);

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
  final settingsService = Get.find<SettingsService>();
  if (settingsService.notificationsEnabled) {
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
