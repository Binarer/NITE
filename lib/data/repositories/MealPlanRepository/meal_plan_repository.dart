import 'package:hive_flutter/hive_flutter.dart';
import '../../models/MealPlanModel/meal_plan_model.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/AppConstants/app_constants.dart';

class MealPlanRepository {
  Box<MealPlanModel> get _box =>
      Hive.box<MealPlanModel>(AppConstants.mealPlansBox);

  final _uuid = const Uuid();

  List<MealPlanModel> getAll() =>
      _box.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  MealPlanModel? getById(String id) => _box.get(id);

  MealPlanModel? getActive() => getAll().isNotEmpty ? getAll().first : null;

  Future<MealPlanModel> save(MealPlanModel plan) async {
    await _box.put(plan.id, plan);
    return plan;
  }

  Future<MealPlanModel> create({String name = 'Мой план питания'}) async {
    final plan = MealPlanModel(id: _uuid.v4(), name: name);
    await _box.put(plan.id, plan);
    return plan;
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Добавляет продукт в ячейку плана (день + приём пищи)
  Future<void> addEntry(
    String planId,
    int weekday,
    MealType meal,
    MealEntry entry,
  ) async {
    final plan = _box.get(planId);
    if (plan == null) return;
    final key = MealPlanModel.entryKey(weekday, meal);
    final updated = Map<String, List<MealEntry>>.from(plan.entries);
    final list = List<MealEntry>.from(updated[key] ?? []);
    list.add(entry);
    updated[key] = list;
    await _box.put(planId, plan.copyWith(entries: updated));
  }

  /// Удаляет продукт из ячейки по индексу
  Future<void> removeEntry(
    String planId,
    int weekday,
    MealType meal,
    int index,
  ) async {
    final plan = _box.get(planId);
    if (plan == null) return;
    final key = MealPlanModel.entryKey(weekday, meal);
    final updated = Map<String, List<MealEntry>>.from(plan.entries);
    final list = List<MealEntry>.from(updated[key] ?? []);
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    updated[key] = list;
    await _box.put(planId, plan.copyWith(entries: updated));
  }

  /// Обновляет граммовку продукта
  Future<void> updateEntryGrams(
    String planId,
    int weekday,
    MealType meal,
    int index,
    double grams,
  ) async {
    final plan = _box.get(planId);
    if (plan == null) return;
    final key = MealPlanModel.entryKey(weekday, meal);
    final updated = Map<String, List<MealEntry>>.from(plan.entries);
    final list = List<MealEntry>.from(updated[key] ?? []);
    if (index < 0 || index >= list.length) return;
    list[index] = list[index].copyWith(grams: grams);
    updated[key] = list;
    await _box.put(planId, plan.copyWith(entries: updated));
  }

  /// Обновляет дневные нормы
  Future<void> updateTargets(
    String planId, {
    double? calories,
    double? protein,
    double? fat,
    double? carbs,
  }) async {
    final plan = _box.get(planId);
    if (plan == null) return;
    await _box.put(
      planId,
      plan.copyWith(
        dailyCalorieTarget: calories,
        dailyProteinTarget: protein,
        dailyFatTarget: fat,
        dailyCarbTarget: carbs,
      ),
    );
  }
}
