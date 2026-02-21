import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/meal_plan_model.dart';
import '../../data/models/scenario_model.dart';
import '../../data/repositories/food_item_repository.dart';
import '../../data/repositories/meal_plan_repository.dart';
import '../../data/repositories/scenario_repository.dart';
import '../../data/repositories/tag_repository.dart';

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
    final id = activePlan.value?.id;
    if (id == null) return;
    await _repo.updateTargets(
      id,
      calories: calories,
      protein: protein,
      fat: fat,
      carbs: carbs,
    );
    reload();
  }

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
}
