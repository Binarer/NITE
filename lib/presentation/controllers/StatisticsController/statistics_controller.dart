import 'package:get/get.dart';
import '../../../core/utils/NutritionCalculator/nutrition_calculator.dart';
import '../../../data/models/FoodItemModel/food_item_model.dart';
import '../../../data/repositories/FoodItemRepository/food_item_repository.dart';
import '../../../data/repositories/TaskRepository/task_repository.dart';
import '../../../data/services/AiService/ai_service.dart';
import '../../../data/services/SettingsService/settings_service.dart';
import '../ScenarioController/scenario_controller.dart';
import '../TagController/tag_controller.dart';


enum StatsPeriod { day, week }

/// Запись веса по дате
class WeightEntry {
  final DateTime date;
  final double kg;
  WeightEntry({required this.date, required this.kg});
}


class StatisticsController extends GetxController {
  final TaskRepository _taskRepo = Get.find<TaskRepository>();
  final FoodItemRepository _foodRepo = Get.find<FoodItemRepository>();

  final Rx<StatsPeriod> period = StatsPeriod.day.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  // Учёт веса
  final RxList<WeightEntry> weightEntries = <WeightEntry>[].obs;
  final RxBool isGeneratingPlan = false.obs;
  final RxString planResult = ''.obs;

  // Для формы добавления веса
  final RxDouble newWeightKg = 70.0.obs;

  // ─── Профиль тела — прокси через SettingsService (единый источник) ────────
  SettingsService get _settings => Get.find<SettingsService>();
  double get heightCm => _settings.heightCm;
  int get age => _settings.age;
  String get gender => _settings.gender;

  @override
  void onInit() {
    super.onInit();
    _loadWeightEntries();
  }

  Future<void> saveBodyProfile() async {
    // Значения хранятся в SettingsService; этот метод — точка сохранения
    // для форм, которые пишут напрямую через _settings.set*().
    // Оставлен для обратной совместимости с вызывающим кодом.
  }

  /// Расчёт BMR по Миффлину-Сент-Жору
  double get bmr {
    final w = weightEntries.isNotEmpty ? weightEntries.last.kg : 70.0;
    if (gender == 'male') {
      return 10 * w + 6.25 * heightCm - 5 * age + 5;
    } else {
      return 10 * w + 6.25 * heightCm - 5 * age - 161;
    }
  }

  /// TDEE с учётом коэффициента активности из SettingsService
  double get tdee => bmr * _settings.activityFactor;

  /// Целевой суточный калораж с учётом цели по весу
  double get targetCaloriesAdjusted {
    final goalType = _settings.weightGoalType;
    final targetKg = _settings.targetWeightKg;
    final deadline = _settings.weightGoalDeadline;
    final currentKg = weightEntries.isNotEmpty ? weightEntries.last.kg : 0.0;

    if (goalType == 'maintain' || targetKg == 0 || deadline == null) {
      return tdee;
    }

    final daysLeft = deadline.difference(DateTime.now()).inDays;
    if (daysLeft <= 0) return tdee;

    // 1 кг жира ≈ 7700 ккал; ограничиваем дельту до ±500 ккал/сут
    final delta = ((targetKg - currentKg) * 7700 / daysLeft).clamp(-500.0, 500.0);
    return (tdee + delta).roundToDouble();
  }

  /// Осталось дней до цели
  int get daysToGoal {
    final deadline = _settings.weightGoalDeadline;
    if (deadline == null) return 0;
    return deadline.difference(DateTime.now()).inDays.clamp(0, 9999);
  }

  /// Разница до целевого веса (кг)
  double get kgToGoal {
    final currentKg = weightEntries.isNotEmpty ? weightEntries.last.kg : 0.0;
    return (_settings.targetWeightKg - currentKg).abs();
  }

  @Deprecated('Use targetCaloriesAdjusted')
  double get targetCaloriesForGain => tdee + 300;

  void setPeriod(StatsPeriod p) => period.value = p;

  void setDate(DateTime d) =>
      selectedDate.value = DateTime(d.year, d.month, d.day);

  // ─── КБЖУ ────────────────────────────────────────────────────────────────

  /// КБЖУ за выбранный день
  NutritionTotals get dailyNutrition => _calcNutrition([selectedDate.value]);

  /// КБЖУ по дням текущей недели (для графика)
  List<MapEntry<DateTime, NutritionTotals>> get weeklyNutritionByDay {
    final start = _weekStart(selectedDate.value);
    return List.generate(7, (i) {
      final day = start.add(Duration(days: i));
      return MapEntry(day, _calcNutrition([day]));
    });
  }

  NutritionTotals get weeklyNutritionTotal {
    return weeklyNutritionByDay.fold(
      NutritionTotals.zero,
      (acc, e) => acc + e.value,
    );
  }

  NutritionTotals _calcNutrition(List<DateTime> dates) {
    var result = NutritionTotals.zero;
    for (final date in dates) {
      final tasks = _taskRepo.getByDate(date);
      result = result + NutritionCalculator.sumTasks(tasks, _foodRepo);
    }
    return result;
  }

  // ─── Вес ──────────────────────────────────────────────────────────────────

  void _loadWeightEntries() {
    weightEntries.value = _weightBox;
  }

  List<WeightEntry> get _weightBox {
    try {
      final settings = Get.find<SettingsService>();
      // Используем reflection через settings box
      final raw = settings.getWeightEntries();
      return raw
          .map((m) => WeightEntry(
                date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
                kg: (m['kg'] as num).toDouble(),
              ))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    } catch (_) {
      return [];
    }
  }

  void addWeightEntry(double kg) {
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    // Заменяем запись на сегодня если есть
    final entries = weightEntries
        .where((e) =>
            !(e.date.year == today.year &&
              e.date.month == today.month &&
              e.date.day == today.day))
        .toList();
    entries.add(WeightEntry(date: today, kg: kg));
    entries.sort((a, b) => a.date.compareTo(b.date));
    weightEntries.value = entries;
    _saveWeightEntries();
  }

  void removeWeightEntry(DateTime date) {
    weightEntries.removeWhere((e) =>
        e.date.year == date.year &&
        e.date.month == date.month &&
        e.date.day == date.day);
    _saveWeightEntries();
  }

  void _saveWeightEntries() {
    try {
      final settings = Get.find<SettingsService>();
      settings.setWeightEntries(weightEntries
          .map((e) => {'date': e.date.millisecondsSinceEpoch, 'kg': e.kg})
          .toList());
    } catch (_) {}
  }

  // ─── AI-план питания ──────────────────────────────────────────────────────

  Future<void> generateNutritionPlan() async {
    final settings = Get.find<SettingsService>();
    final provider = settings.aiProvider;
    final apiKey = settings.getApiKey(provider);
    if (apiKey.isEmpty) {
      planResult.value = 'Нет API ключа. Настройте AI в Настройках.';
      return;
    }

    isGeneratingPlan.value = true;
    planResult.value = '';

    try {
      final weightKg = weightEntries.isNotEmpty
          ? weightEntries.last.kg
          : 70.0;

      // Собираем библиотеку еды
      final foods = _foodRepo.getAll();
      final foodLibrary = foods.map((f) => {
            'name': f.name,
            'calories': f.calories,
            'proteins': f.macros.proteins,
            'fats': f.macros.fats,
            'carbs': f.macros.carbs,
          }).toList();

      if (foodLibrary.isEmpty) {
        planResult.value = 'Библиотека еды пуста. Добавьте продукты сначала.';
        isGeneratingPlan.value = false;
        return;
      }

      final service = AiService(
        provider: provider,
        apiKey: apiKey,
        model: settings.getModel(provider),
      );

      final plan = await service.generateNutritionPlan(
        weightKg: weightKg,
        foodLibrary: foodLibrary,
        goal: 'набор мышечной массы',
        heightCm: heightCm,
        age: age,
        gender: gender,
      );
      planResult.value = plan;

      // Создаём сценарий из плана
      await _createScenarioFromPlan(plan, foods);
    } catch (e) {
      planResult.value = 'Ошибка: $e';
    } finally {
      isGeneratingPlan.value = false;
    }
  }

  Future<void> _createScenarioFromPlan(
      String planText, List<FoodItemModel> foods) async {
    try {
      final scenarioCtrl = Get.find<ScenarioController>();
      final tagCtrl = Get.find<TagController>();

      // Ищем тег "Еда"
      final foodTag = tagCtrl.tags.firstWhereOrNull(
        (t) => t.name.toLowerCase().contains('еда'),
      );

      // Парсим план по дням
      final weekdayMap = {
        'понедельник': 1, 'вторник': 2, 'среда': 3, 'среду': 3,
        'четверг': 4, 'пятница': 5, 'пятницу': 5,
        'суббота': 6, 'субботу': 6, 'воскресенье': 7,
        'пн': 1, 'вт': 2, 'ср': 3, 'чт': 4, 'пт': 5, 'сб': 6, 'вс': 7,
      };

      final scenarioTasks = <dynamic>[];
      final lines = planText.split('\n');
      int currentWeekday = 1;

      for (final line in lines) {
        final lower = line.toLowerCase().trim();
        // Ищем день
        for (final entry in weekdayMap.entries) {
          if (lower.contains(entry.key)) {
            currentWeekday = entry.value;
            break;
          }
        }
        // Ищем приём пищи (ЗАВТРАК/ОБЕД/УЖИН)
        if (lower.startsWith('завтрак') ||
            lower.startsWith('обед') ||
            lower.startsWith('ужин')) {
          final parts = line.split(':');
          if (parts.length > 1) {
            final mealName = parts[0].trim();
            final content = parts[1].trim();
            // Ищем продукт в библиотеке
            final matchedFood = foods.firstWhereOrNull((f) =>
                content.toLowerCase().contains(f.name.toLowerCase()));

            final taskName = matchedFood != null
                ? '$mealName: ${matchedFood.name}'
                : '$mealName: $content';

            scenarioTasks.add({
              'name': taskName,
              'weekday': currentWeekday,
              'tagIds': foodTag != null ? [foodTag.id] : <String>[],
              'foodItemId': matchedFood?.id,
            });
          }
        }
      }

      if (scenarioTasks.isNotEmpty) {
        await scenarioCtrl.createScenarioFromAiPlan(
          name: 'AI-план питания (набор массы)',
          tasks: scenarioTasks,
        );
      }
    } catch (_) {
      // Не прерываем показ плана если создание сценария не удалось
    }
  }

  // ─── helpers ──────────────────────────────────────────────────────────────

  DateTime _weekStart(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  String get selectedDateLabel {
    final d = selectedDate.value;
    final months = [
      '', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  String get weekLabel {
    final start = _weekStart(selectedDate.value);
    final end = start.add(const Duration(days: 6));
    final months = [
      '', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    return '${start.day} ${months[start.month]} — ${end.day} ${months[end.month]}';
  }

}
