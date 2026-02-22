import 'dart:convert';
import 'package:get/get.dart';
import '../../../data/models/FoodItemModel/food_item_model.dart';
import '../../../data/models/MealPlanModel/meal_plan_model.dart';
import '../../../data/models/ScenarioModel/scenario_model.dart';
import '../../../data/repositories/FoodItemRepository/food_item_repository.dart';
import '../../../data/repositories/MealPlanRepository/meal_plan_repository.dart';
import '../../../data/repositories/ScenarioRepository/scenario_repository.dart';
import '../../../data/repositories/TagRepository/tag_repository.dart';
import '../../../data/services/AiService/ai_service.dart';
import '../../../data/services/SettingsService/settings_service.dart';
import '../StatisticsController/statistics_controller.dart';
import 'package:uuid/uuid.dart';

class MealPlanController extends GetxController {
  final MealPlanRepository _repo = Get.find<MealPlanRepository>();
  final FoodItemRepository _foodRepo = Get.find<FoodItemRepository>();
  final ScenarioRepository _scenarioRepo = Get.find<ScenarioRepository>();
  final _uuid = const Uuid();

  final Rx<MealPlanModel?> activePlan = Rx<MealPlanModel?>(null);
  final RxInt selectedWeekday = 0.obs; // 0=ПН, 6=ВС

  @override
  void onInit() {
    super.onInit();
    _loadOrCreate();
  }

  void _loadOrCreate() async {
    var plan = _repo.getActive();
    plan ??= await _repo.create();
    activePlan.value = plan;
  }

  void reload() {
    activePlan.value = _repo.getById(activePlan.value?.id ?? '');
  }

  void selectWeekday(int weekday) => selectedWeekday.value = weekday;

  // ─── Добавление / удаление ────────────────────────────────────────────────

  Future<void> addEntry(MealType meal, MealEntry entry) async {
    final id = activePlan.value?.id;
    if (id == null) return;
    await _repo.addEntry(id, selectedWeekday.value, meal, entry);
    reload();
  }

  Future<void> removeEntry(MealType meal, int index) async {
    final id = activePlan.value?.id;
    if (id == null) return;
    await _repo.removeEntry(id, selectedWeekday.value, meal, index);
    reload();
  }

  Future<void> updateGrams(MealType meal, int index, double grams) async {
    final id = activePlan.value?.id;
    if (id == null) return;
    await _repo.updateEntryGrams(id, selectedWeekday.value, meal, index, grams);
    reload();
  }

  // ─── Нормы ────────────────────────────────────────────────────────────────

  Future<void> updateTargets({
    double? calories,
    double? protein,
    double? fat,
    double? carbs,
  }) async {
    final settings = Get.find<SettingsService>();
    if (calories != null) await settings.setDailyCalories(calories);
    if (protein != null) await settings.setDailyProtein(protein);
    if (fat != null) await settings.setDailyFat(fat);
    if (carbs != null) await settings.setDailyCarbs(carbs);
  }

  /// Дневные нормы — единый источник из SettingsService
  double get targetCalories => Get.find<SettingsService>().dailyCalories;
  double get targetProtein  => Get.find<SettingsService>().dailyProtein;
  double get targetFat      => Get.find<SettingsService>().dailyFat;
  double get targetCarbs    => Get.find<SettingsService>().dailyCarbs;

  // ─── Подсчёт КБЖУ ────────────────────────────────────────────────────────

  /// КБЖУ для конкретного приёма пищи в выбранном дне
  Map<String, double> macrosForMeal(int weekday, MealType meal) {
    final plan = activePlan.value;
    if (plan == null) return _emptyMacros();
    final entries = plan.getEntries(weekday, meal);
    return _sumMacros(entries);
  }

  /// Суммарное КБЖУ за выбранный день
  Map<String, double> macrosForDay(int weekday) {
    double kcal = 0, protein = 0, fat = 0, carb = 0;
    for (final meal in MealType.values) {
      final m = macrosForMeal(weekday, meal);
      kcal += m['kcal']!;
      protein += m['protein']!;
      fat += m['fat']!;
      carb += m['carb']!;
    }
    return {'kcal': kcal, 'protein': protein, 'fat': fat, 'carb': carb};
  }

  Map<String, double> _sumMacros(List<MealEntry> entries) {
    double kcal = 0, protein = 0, fat = 0, carb = 0;
    for (final e in entries) {
      final food = _foodRepo.getById(e.foodItemId);
      if (food == null) continue;
      final ratio = e.grams / 100.0;
      kcal += food.calories * ratio;
      protein += food.macros.proteins * ratio;
      fat += food.macros.fats * ratio;
      carb += food.macros.carbs * ratio;
    }
    return {'kcal': kcal, 'protein': protein, 'fat': fat, 'carb': carb};
  }

  Map<String, double> _emptyMacros() =>
      {'kcal': 0, 'protein': 0, 'fat': 0, 'carb': 0};

  // ─── Создание сценария из плана питания ──────────────────────────────────

  Future<String?> saveAsScenario({required String name}) async {
    final plan = activePlan.value;
    if (plan == null) return null;

    // Ищем тег "Еда"
    final foodTagId = _findFoodTagId();

    final tasks = <ScenarioTask>[];
    for (int wd = 0; wd < 7; wd++) {
      for (final meal in MealType.values) {
        final entries = plan.getEntries(wd, meal);
        if (entries.isEmpty) continue;

        // Формируем название задачи
        final foods = entries.map((e) {
          final food = _foodRepo.getById(e.foodItemId);
          return food != null
              ? '${food.name} (${e.grams.toStringAsFixed(0)}г)'
              : 'Продукт';
        }).join(', ');

        final taskName = '${meal.emoji} ${meal.label}: $foods';

        // Считаем КБЖУ для описания
        final macros = _sumMacros(entries);
        final desc =
            '🔥 ${macros['kcal']!.toStringAsFixed(0)} ккал | '
            'Б ${macros['protein']!.toStringAsFixed(1)}г | '
            'Ж ${macros['fat']!.toStringAsFixed(1)}г | '
            'У ${macros['carb']!.toStringAsFixed(1)}г';

        tasks.add(ScenarioTask(
          id: _uuid.v4(),
          name: taskName,
          description: desc,
          weekday: wd,
          tagIds: foodTagId != null ? [foodTagId] : [],
          priority: 2,
          startMinutes: meal.defaultStartMinutes,
          endMinutes: meal.defaultStartMinutes + 30,
        ));
      }
    }

    if (tasks.isEmpty) return null;

    final scenario = ScenarioModel(
      id: _uuid.v4(),
      name: name,
      tasks: tasks,
    );
    await _scenarioRepo.save(scenario);
    return scenario.id;
  }

  String? _findFoodTagId() {
    try {
      final tagRepo = Get.find<TagRepository>();
      final foodTag = tagRepo.getAll().firstWhereOrNull(
            (t) => t.name.toLowerCase().contains('еда') ||
                t.name.toLowerCase().contains('food'),
          );
      return foodTag?.id;
    } catch (_) {
      return null;
    }
  }

  // ─── AI-план питания ──────────────────────────────────────────────────────

  final RxBool isGeneratingPlan = false.obs;
  final RxString aiPlanError = ''.obs;

  /// Генерирует план питания через AI и заполняет activePlan
  Future<void> generateAiPlan({required String goal}) async {
    final settings = Get.find<SettingsService>();
    final provider = settings.aiProvider;
    final apiKey = settings.getApiKey(provider);

    if (apiKey.isEmpty) {
      aiPlanError.value = 'Нет API ключа. Настройте AI в Настройках.';
      return;
    }

    final foods = _foodRepo.getAll();
    if (foods.isEmpty) {
      aiPlanError.value = 'Библиотека еды пуста. Добавьте продукты сначала.';
      return;
    }

    isGeneratingPlan.value = true;
    aiPlanError.value = '';

    try {
      // Получаем профиль пользователя
      final statsCtrl = Get.find<StatisticsController>();
      final weightKg = statsCtrl.weightEntries.isNotEmpty
          ? statsCtrl.weightEntries.last.kg
          : 70.0;
      final heightCm = statsCtrl.heightCm;
      final age = statsCtrl.age;
      final gender = statsCtrl.gender;

      // Строим строгий промпт с JSON-форматом ответа
      final foodList = foods.map((f) =>
          '{"id":"${f.id}","name":"${f.name}","kcal":${f.calories.toStringAsFixed(1)},'
          '"p":${f.macros.proteins.toStringAsFixed(1)},'
          '"f":${f.macros.fats.toStringAsFixed(1)},'
          '"c":${f.macros.carbs.toStringAsFixed(1)}}').join(',\n');

      final double bmr = gender == 'male'
          ? 10 * weightKg + 6.25 * heightCm - 5 * age + 5
          : 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
      final double tdee = bmr * settings.activityFactor;
      final double targetKcal = goal == 'loss'
          ? (tdee - 400).clamp(1200, 99999)
          : goal == 'gain'
              ? tdee + 300
              : tdee;
      final double targetProtein = weightKg * (goal == 'gain' ? 2.0 : 1.8);

      final prompt = '''
Ты — диетолог. Составь план питания на неделю (7 дней, 0=ПН ... 6=ВС).

Профиль:
- Пол: ${gender == 'male' ? 'мужчина' : 'женщина'}, возраст $age лет, рост ${heightCm.toStringAsFixed(0)} см, вес ${weightKg.toStringAsFixed(1)} кг
- Цель: $goal (tdee=${tdee.toStringAsFixed(0)} ккал, целевая=${targetKcal.toStringAsFixed(0)} ккал/день)
- Белок: минимум ${targetProtein.toStringAsFixed(0)} г/день

Доступные продукты (используй ТОЛЬКО их, по полю "id"):
[$foodList]

Верни СТРОГО валидный JSON без markdown, без комментариев:
{
  "days": [
    {
      "weekday": 0,
      "meals": [
        {
          "type": "breakfast",
          "entries": [{"food_id": "...", "grams": 150}]
        },
        {
          "type": "lunch",
          "entries": [{"food_id": "...", "grams": 200}]
        },
        {
          "type": "dinner",
          "entries": [{"food_id": "...", "grams": 180}]
        },
        {
          "type": "snack",
          "entries": [{"food_id": "...", "grams": 100}]
        }
      ]
    }
  ]
}

Требования:
- weekday: 0=ПН, 1=ВТ, 2=СР, 3=ЧТ, 4=ПТ, 5=СБ, 6=ВС
- type: только "breakfast", "lunch", "dinner", "snack"
- grams: целое число > 0
- food_id: строго из поля "id" предоставленных продуктов
- Каждый день: минимум 3 приёма пищи
- Суточная калорийность близко к ${targetKcal.toStringAsFixed(0)} ккал
- Только JSON, никакого текста вокруг
''';

      final service = AiService(
        provider: provider,
        apiKey: apiKey,
        model: settings.getModel(provider),
      );

      final raw = await service.sendRaw(prompt, maxTokens: 3000);
      if (raw == null || raw.isEmpty) {
        aiPlanError.value = 'AI не вернул ответ. Попробуйте ещё раз.';
        return;
      }

      // Извлекаем JSON из ответа (на случай если модель добавила текст)
      final jsonStr = _extractJson(raw);
      if (jsonStr == null) {
        aiPlanError.value = 'Не удалось разобрать ответ AI. Попробуйте ещё раз.';
        return;
      }

      await _applyAiPlanJson(jsonStr, foods);
    } catch (e) {
      aiPlanError.value = 'Ошибка: $e';
    } finally {
      isGeneratingPlan.value = false;
    }
  }

  /// Извлекает первый JSON-объект из строки
  String? _extractJson(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return null;
    return raw.substring(start, end + 1);
  }

  /// Парсит JSON ответа AI и записывает продукты в activePlan
  Future<void> _applyAiPlanJson(String jsonStr, List<FoodItemModel> foods) async {
    try {
      // Простой JSON парсинг без dart:convert через RegExp
      // (dart:convert доступен — используем его через dynamic)
      final decoded = _parseJson(jsonStr);
      if (decoded == null) return;

      final days = decoded['days'] as List<dynamic>?;
      if (days == null) return;

      // Очищаем текущий план
      final planId = activePlan.value?.id;
      if (planId == null) return;

      final newEntries = <String, List<MealEntry>>{};

      for (final day in days) {
        final weekday = (day['weekday'] as num?)?.toInt();
        if (weekday == null || weekday < 0 || weekday > 6) continue;

        final meals = day['meals'] as List<dynamic>?;
        if (meals == null) continue;

        for (final meal in meals) {
          final typeStr = meal['type'] as String?;
          final mealType = _mealTypeFromString(typeStr);
          if (mealType == null) continue;

          final entries = meal['entries'] as List<dynamic>?;
          if (entries == null) continue;

          final mealEntries = <MealEntry>[];
          for (final e in entries) {
            final foodId = e['food_id'] as String?;
            final grams = (e['grams'] as num?)?.toDouble() ?? 100.0;
            if (foodId == null) continue;
            // Проверяем что продукт существует
            final food = foods.firstWhereOrNull((f) => f.id == foodId);
            if (food == null) continue;
            mealEntries.add(MealEntry(foodItemId: foodId, grams: grams));
          }

          if (mealEntries.isNotEmpty) {
            final key = MealPlanModel.entryKey(weekday, mealType);
            newEntries[key] = mealEntries;
          }
        }
      }

      // Сохраняем новый план
      final plan = activePlan.value!;
      final updated = plan.copyWith(entries: newEntries);
      await _repo.save(updated);
      activePlan.value = updated;
    } catch (e) {
      aiPlanError.value = 'Ошибка применения плана: $e';
    }
  }

  MealType? _mealTypeFromString(String? s) {
    switch (s) {
      case 'breakfast': return MealType.breakfast;
      case 'lunch': return MealType.lunch;
      case 'dinner': return MealType.dinner;
      case 'snack': return MealType.snack;
      default: return null;
    }
  }

  /// JSON-парсер через dart:convert
  Map<String, dynamic>? _parseJson(String s) {
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ─── Замена продукта на похожий по КБЖУ ─────────────────────────────────

  /// Возвращает список продуктов похожих по КБЖУ (±30%) для замены
  List<FoodItemModel> getSimilarFoods(String foodItemId, double grams) {
    final source = _foodRepo.getById(foodItemId);
    if (source == null) return [];

    final ratio = grams / 100.0;
    final targetKcal = source.calories * ratio;
    final targetP = source.macros.proteins * ratio;

    return _foodRepo.getAll().where((f) {
      if (f.id == foodItemId) return false;
      final r = grams / 100.0;
      final kcalDiff = (f.calories * r - targetKcal).abs();
      final pDiff = (f.macros.proteins * r - targetP).abs();
      // Схожесть по калориям ±25% и по белкам ±30%
      return kcalDiff <= targetKcal * 0.25 && pDiff <= (targetP + 1) * 0.30;
    }).toList()
      ..sort((a, b) {
        // Сортируем по близости калорий
        final ra = grams / 100.0;
        final diffA = (a.calories * ra - targetKcal).abs();
        final diffB = (b.calories * ra - targetKcal).abs();
        return diffA.compareTo(diffB);
      });
  }

  /// Заменяет продукт в приёме пищи
  Future<void> replaceEntry(
      MealType meal, int index, String newFoodId, double grams) async {
    final id = activePlan.value?.id;
    if (id == null) return;
    await _repo.removeEntry(id, selectedWeekday.value, meal, index);
    await _repo.addEntryAt(id, selectedWeekday.value, meal,
        MealEntry(foodItemId: newFoodId, grams: grams), index);
    reload();
  }
}
