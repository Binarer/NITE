import 'package:get/get.dart';
import '../../../core/utils/AppLogger/app_logger.dart';
import '../../../core/utils/NutritionCalculator/nutrition_calculator.dart';
import '../../repositories/AiReportRepository/ai_report_repository.dart';
import '../../repositories/FoodItemRepository/food_item_repository.dart';
import '../../repositories/TaskRepository/task_repository.dart';
import '../AiService/ai_service.dart';
import '../NotificationService/notification_service.dart';
import '../SettingsService/settings_service.dart';

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  AiReportRepository get _reportRepo => Get.find<AiReportRepository>();

  // ─── Генерация ежедневного отчёта ─────────────────────────────────────────

  Future<String?> generateDailyReport({DateTime? date}) async {
    log.info('ReportService', 'Генерация ежедневного отчёта...');
    final settings = Get.find<SettingsService>();
    final provider = settings.aiProvider;
    final apiKey = settings.getApiKey(provider);
    if (apiKey.isEmpty) {
      log.warning('ReportService', 'API ключ не задан — отчёт пропущен');
      return null;
    }

    final targetDate = date ?? DateTime.now();
    final taskRepo = Get.find<TaskRepository>();
    final foodRepo = Get.find<FoodItemRepository>();
    final tasks = taskRepo.getByDate(targetDate);

    final completed = tasks.where((t) => t.isCompleted).toList();
    final pending = tasks.where((t) => !t.isCompleted).toList();

    // Подсчёт КБЖУ из выполненных задач с тегом «Еда»
    final foodTasks = completed.where((t) => t.foodItemIds.isNotEmpty).toList();
    final nutrition = NutritionCalculator.sumTasks(foodTasks, foodRepo);

    // Текущий вес и цель
    final weightEntries = settings.getWeightEntries();
    final currentWeight = weightEntries.isNotEmpty
        ? (weightEntries.last['kg'] as num?)?.toDouble()
        : null;
    final targetWeight = settings.targetWeightKg > 0 ? settings.targetWeightKg : null;
    final calorieTarget = settings.dailyCalories;

    final service = AiService(
      provider: provider,
      apiKey: apiKey,
      model: settings.getModel(provider),
    );

    final day = targetDate;
    final months = ['', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
        'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    final dateLabel = '${day.day} ${months[day.month]} ${day.year}';

    final completedList = completed.isEmpty
        ? 'нет выполненных задач'
        : completed.map((t) => '• ${t.name} (приоритет: ${t.priority})').join('\n');
    final pendingList = pending.isEmpty
        ? 'все задачи выполнены'
        : pending.map((t) => '• ${t.name}').join('\n');

    final nutritionBlock = nutrition.calories > 0
        ? '''
Питание за день:
• Калории: ${nutrition.calories.toStringAsFixed(0)} / ${calorieTarget.toStringAsFixed(0)} ккал
• Белки: ${nutrition.proteins.toStringAsFixed(1)}г  Жиры: ${nutrition.fats.toStringAsFixed(1)}г  Углеводы: ${nutrition.carbs.toStringAsFixed(1)}г'''
        : '';

    final weightBlock = currentWeight != null
        ? '\nВес: ${currentWeight.toStringAsFixed(1)} кг${targetWeight != null ? ' (цель: ${targetWeight.toStringAsFixed(1)} кг)' : ''}'
        : '';

    final prompt = '''
Ты — персональный ассистент по продуктивности и здоровью. Дай краткий итог дня ($dateLabel).

Выполненные задачи:
$completedList

Невыполненные задачи:
$pendingList
$nutritionBlock$weightBlock

Напиши 2-3 предложения: оцени день, похвали или мягко подбодри. Если есть данные о питании — прокомментируй кратко. Заверши одним коротким советом на завтра.
Ответ на русском языке, дружелюбно. Не более 180 слов.
''';

    try {
      final content = await service.sendRaw(prompt, maxTokens: 250);
      if (content == null || content.isEmpty) return null;

      // Сохраняем со snapshot-данными
      final weightEntries2 = settings.getWeightEntries();
      final snapWeight = weightEntries2.isNotEmpty
          ? (weightEntries2.last['kg'] as num?)?.toDouble()
          : null;
      // TDEE: BMR × activityFactor (простой расчёт)
      final snapTdee = snapWeight != null
          ? (() {
              final h = settings.heightCm;
              final a = settings.age;
              final g = settings.gender;
              final bmr = g == 'male'
                  ? 10 * snapWeight + 6.25 * h - 5 * a + 5
                  : 10 * snapWeight + 6.25 * h - 5 * a - 161;
              return bmr * settings.activityFactor;
            })()
          : null;
      await _reportRepo.saveDailyReport(
        date: targetDate,
        content: content,
        caloriesConsumed: nutrition.calories > 0 ? nutrition.calories : null,
        weightKg: snapWeight,
        tdee: snapTdee,
      );

      // Уведомление
      final short = content.length > 100 ? '${content.substring(0, 100)}...' : content;
      await NotificationService().showDailyReportNotification(short, targetDate);
      log.success('ReportService', 'Ежедневный отчёт сгенерирован и отправлен');
      return content;
    } on Exception catch (e, st) {
      log.error('ReportService', 'Ошибка ежедневного отчёта: $e\n$st');
      return null;
    }
  }

  // ─── Генерация еженедельного отчёта ──────────────────────────────────────

  Future<String?> generateWeeklyReport({DateTime? weekStart}) async {
    log.info('ReportService', 'Генерация еженедельного отчёта...');
    final settings = Get.find<SettingsService>();
    final provider = settings.aiProvider;
    final apiKey = settings.getApiKey(provider);
    if (apiKey.isEmpty) {
      log.warning('ReportService', 'API ключ не задан — недельный отчёт пропущен');
      return null;
    }

    final taskRepo = Get.find<TaskRepository>();
    final foodRepo = Get.find<FoodItemRepository>();
    final now = weekStart ?? _lastWeekStart();
    final tasks = taskRepo.getByWeek(now);
    final completed = tasks.where((t) => t.isCompleted).toList();

    // КБЖУ за неделю из выполненных задач с едой
    final foodTasks = completed.where((t) => t.foodItemIds.isNotEmpty).toList();
    final weekNutrition = NutritionCalculator.sumTasks(foodTasks, foodRepo);
    final calorieTarget = settings.dailyCalories;

    // Динамика веса за неделю
    final weightEntries = settings.getWeightEntries();
    String weightBlock = '';
    if (weightEntries.length >= 2) {
      final first = (weightEntries.first['kg'] as num?)?.toDouble();
      final last = (weightEntries.last['kg'] as num?)?.toDouble();
      if (first != null && last != null) {
        final delta = last - first;
        final sign = delta >= 0 ? '+' : '';
        weightBlock = '\nДинамика веса за период: ${first.toStringAsFixed(1)} → ${last.toStringAsFixed(1)} кг ($sign${delta.toStringAsFixed(1)} кг)';
      }
    } else if (weightEntries.isNotEmpty) {
      final kg = (weightEntries.last['kg'] as num?)?.toDouble();
      if (kg != null) weightBlock = '\nТекущий вес: ${kg.toStringAsFixed(1)} кг';
    }

    final service = AiService(
      provider: provider,
      apiKey: apiKey,
      model: settings.getModel(provider),
    );

    final tasksList = completed.isEmpty
        ? 'задач не выполнено'
        : completed.map((t) => '• ${t.name} (приоритет: ${t.priority})').join('\n');

    final weekNutritionBlock = weekNutrition.calories > 0
        ? '''
Питание за неделю (суммарно):
• Калории: ${weekNutrition.calories.toStringAsFixed(0)} (норма ~${(calorieTarget * 7).toStringAsFixed(0)} ккал)
• Белки: ${weekNutrition.proteins.toStringAsFixed(1)}г  Жиры: ${weekNutrition.fats.toStringAsFixed(1)}г  Углеводы: ${weekNutrition.carbs.toStringAsFixed(1)}г'''
        : '';

    final prompt = '''
Ты — персональный коуч по продуктивности и здоровью. На основе данных за прошлую неделю дай оценку и совет.

Выполненные задачи:
$tasksList
$weekNutritionBlock$weightBlock

Напиши 3-5 предложений: оцени неделю по задачам и питанию, выдели сильные стороны, дай один конкретный совет на следующую неделю.
Ответ на русском языке, дружелюбно и конструктивно. Не более 220 слов.
''';

    try {
      final content = await service.sendRaw(prompt, maxTokens: 350);
      if (content == null || content.isEmpty) return null;

      final snapEntries = settings.getWeightEntries();
      final snapWeightW = snapEntries.isNotEmpty
          ? (snapEntries.last['kg'] as num?)?.toDouble()
          : null;
      final snapTdeeW = snapWeightW != null
          ? (() {
              final h = settings.heightCm;
              final a = settings.age;
              final g = settings.gender;
              final bmr = g == 'male'
                  ? 10 * snapWeightW + 6.25 * h - 5 * a + 5
                  : 10 * snapWeightW + 6.25 * h - 5 * a - 161;
              return bmr * settings.activityFactor;
            })()
          : null;
      await _reportRepo.saveWeeklyReport(
        weekStart: now,
        content: content,
        caloriesConsumed: weekNutrition.calories > 0 ? weekNutrition.calories : null,
        weightKg: snapWeightW,
        tdee: snapTdeeW,
      );

      final short = content.length > 100 ? '${content.substring(0, 100)}...' : content;
      await NotificationService().showWeeklyReportNotification(short);
      log.success('ReportService', 'Еженедельный отчёт сгенерирован и отправлен');
      return content;
    } on Exception catch (e, st) {
      log.error('ReportService', 'Ошибка еженедельного отчёта: $e\n$st');
      return null;
    }
  }

  // ─── Планировщик уведомлений ──────────────────────────────────────────────

  /// Планирует ежедневный отчёт в конце дня (22:00)
  Future<void> scheduleDailyReport() async {
    await NotificationService().scheduleDailyReport();
  }

  /// Отменяет ежедневный отчёт
  Future<void> cancelDailyReport() async {
    await NotificationService().cancelDailyReport();
  }

  // ─── Доступ к репозиторию ─────────────────────────────────────────────────

  AiReportRepository get repository => _reportRepo;

  // ─── helpers ──────────────────────────────────────────────────────────────

  DateTime _lastWeekStart() {
    final now = DateTime.now();
    // Сначала находим текущий понедельник, затем откатываемся на 7 дней назад
    final thisMonday = now.subtract(Duration(days: now.weekday - 1));
    final lastMonday = thisMonday.subtract(const Duration(days: 7));
    return DateTime(lastMonday.year, lastMonday.month, lastMonday.day);
  }
}
