import 'package:get/get.dart';
import '../../data/models/food_item_model.dart';
import '../../data/repositories/food_item_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/settings_service.dart';
import 'scenario_controller.dart';
import 'tag_controller.dart';

enum StatsPeriod { day, week }

/// Запись веса по дате
class WeightEntry {
  final DateTime date;
  final double kg;
  WeightEntry({required this.date, required this.kg});
}

/// Итоговое КБЖУ за период
class NutritionTotals {
  final double calories;
  final double proteins;
  final double fats;
  final double carbs;
  const NutritionTotals({
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
  });

  NutritionTotals operator +(NutritionTotals other) => NutritionTotals(
        calories: calories + other.calories,
        proteins: proteins + other.proteins,
        fats: fats + other.fats,
        carbs: carbs + other.carbs,
      );

  static const zero = NutritionTotals(calories: 0, proteins: 0, fats: 0, carbs: 0);
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

  // ─── Профиль тела ──────────────────────────────────────────────────────────
  final RxDouble heightCm = 175.0.obs;
  final RxInt age = 25.obs;
  final RxString gender = 'male'.obs; // 'male' | 'female'

  @override
  void onInit() {
    super.onInit();
    _loadWeightEntries();
    _loadBodyProfile();
  }

  void _loadBodyProfile() {
    try {
      final settings = Get.find<SettingsService>();
      heightCm.value = settings.heightCm;
      age.value = settings.age;
      gender.value = settings.gender;
    } catch (_) {}
  }

  Future<void> saveBodyProfile() async {
    try {
      final settings = Get.find<SettingsService>();
      await settings.setHeightCm(heightCm.value);
      await settings.setAge(age.value);
      await settings.setGender(gender.value);
    } catch (_) {}
  }

  /// Расчёт BMR по Миффлину-Сент-Жору
  double get bmr {
    final w = weightEntries.isNotEmpty ? weightEntries.last.kg : 70.0;
    if (gender.value == 'male') {
      return 10 * w + 6.25 * heightCm.value - 5 * age.value + 5;
    } else {
      return 10 * w + 6.25 * heightCm.value - 5 * age.value - 161;
    }
  }

  /// TDEE (умеренная активность × 1.55)
  double get tdee => bmr * 1.55;

  /// Рекомендуемая калорийность для набора массы
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
      for (final task in tasks) {
        final ids = task.foodItemIds.isNotEmpty
            ? task.foodItemIds
            : (task.foodItemId != null ? [task.foodItemId!] : <String>[]);
        for (final id in ids) {
          final food = _foodRepo.getById(id);
          if (food == null) continue;
          final ratio = task.foodGrams / 100.0;
          result = NutritionTotals(
            calories: result.calories + food.calories * ratio,
            proteins: result.proteins + food.macros.proteins * ratio,
            fats: result.fats + food.macros.fats * ratio,
            carbs: result.carbs + food.macros.carbs * ratio,
          );
        }
      }
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
        heightCm: heightCm.value,
        age: age.value,
        gender: gender.value,
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

  // Удаляем неиспользуемый dayNames
}
