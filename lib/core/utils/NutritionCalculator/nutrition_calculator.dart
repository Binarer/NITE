
import '../../../data/models/FoodItemModel/food_item_model.dart';
import '../../../data/models/MealPlanModel/meal_plan_model.dart';
import '../../../data/models/TaskModel/task_model.dart';
import '../../../data/repositories/FoodItemRepository/food_item_repository.dart';

/// Итоговые значения КБЖУ
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

  static const zero = NutritionTotals(
    calories: 0,
    proteins: 0,
    fats: 0,
    carbs: 0,
  );

  NutritionTotals operator +(NutritionTotals other) => NutritionTotals(
        calories: calories + other.calories,
        proteins: proteins + other.proteins,
        fats: fats + other.fats,
        carbs: carbs + other.carbs,
      );

  NutritionTotals operator *(double factor) => NutritionTotals(
        calories: calories * factor,
        proteins: proteins * factor,
        fats: fats * factor,
        carbs: carbs * factor,
      );

  @override
  String toString() =>
      'NutritionTotals(kcal: ${calories.toStringAsFixed(1)}, '
      'P: ${proteins.toStringAsFixed(1)}, '
      'F: ${fats.toStringAsFixed(1)}, '
      'C: ${carbs.toStringAsFixed(1)})';
}

/// Утилита расчёта КБЖУ.
/// Единая формула: значение = базовое_на_100г × граммы / 100.
/// Используется в StatisticsController, MealPlanController, виджетах задач.
class NutritionCalculator {
  NutritionCalculator._();

  /// КБЖУ одного продукта при заданной граммовке.
  static NutritionTotals fromFoodItem(FoodItemModel item, double grams) {
    final factor = grams / 100.0;
    return NutritionTotals(
      calories: item.calories * factor,
      proteins: item.macros.proteins * factor,
      fats: item.macros.fats * factor,
      carbs: item.macros.carbs * factor,
    );
  }

  /// КБЖУ списка [MealEntry] из плана питания.
  static NutritionTotals sumMealEntries(
    List<MealEntry> entries,
    FoodItemRepository repo,
  ) {
    return entries.fold(NutritionTotals.zero, (acc, entry) {
      final item = repo.getById(entry.foodItemId);
      if (item == null) return acc;
      return acc + fromFoodItem(item, entry.grams);
    });
  }

  /// КБЖУ задачи с тегом «Еда».
  /// Читает [foodItemIds] + [foodItemGrams]; если граммаж не задан — 100 г.
  static NutritionTotals fromTask(TaskModel task, FoodItemRepository repo) {
    var total = NutritionTotals.zero;

    for (final id in task.foodItemIds) {
      final item = repo.getById(id);
      if (item == null) continue;
      // Приоритет: Map foodItemGrams → устаревший foodGrams → 100 г
      final grams = task.foodItemGrams.isNotEmpty
          ? (task.foodItemGrams[id] ?? task.foodGrams)
          : task.foodGrams;
      total = total + fromFoodItem(item, grams);
    }

    // Обратная совместимость: старое одиночное поле foodItemId
    if (task.foodItemIds.isEmpty && task.foodItemId != null) {
      final item = repo.getById(task.foodItemId!);
      if (item != null) {
        total = total + fromFoodItem(item, task.foodGrams);
      }
    }

    return total;
  }

  /// КБЖУ списка задач (например, всех задач за день с тегом «Еда»).
  static NutritionTotals sumTasks(
    List<TaskModel> tasks,
    FoodItemRepository repo,
  ) {
    return tasks.fold(
      NutritionTotals.zero,
      (acc, task) => acc + fromTask(task, repo),
    );
  }
}
