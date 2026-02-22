import 'package:hive/hive.dart';
import '../../../core/constants/AppConstants/app_constants.dart';
part 'meal_plan_model.g.dart';

/// Приём пищи: завтрак, обед, ужин, перекус
enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get label {
    switch (this) {
      case MealType.breakfast: return 'Завтрак';
      case MealType.lunch:     return 'Обед';
      case MealType.dinner:    return 'Ужин';
      case MealType.snack:     return 'Перекус';
    }
  }

  String get emoji {
    switch (this) {
      case MealType.breakfast: return '🌅';
      case MealType.lunch:     return '☀️';
      case MealType.dinner:    return '🌙';
      case MealType.snack:     return '🍎';
    }
  }

  /// Время начала приёма пищи по умолчанию (в минутах от полуночи)
  int get defaultStartMinutes {
    switch (this) {
      case MealType.breakfast: return 8 * 60;   // 08:00
      case MealType.lunch:     return 13 * 60;  // 13:00
      case MealType.dinner:    return 19 * 60;  // 19:00
      case MealType.snack:     return 16 * 60;  // 16:00
    }
  }
}

/// Одна позиция в плане питания (продукт + граммовка)
@HiveType(typeId: AppConstants.mealEntryTypeId)
class MealEntry extends HiveObject {
  @HiveField(0)
  String foodItemId;

  @HiveField(1)
  double grams;

  MealEntry({
    required this.foodItemId,
    this.grams = 100.0,
  });

  MealEntry copyWith({String? foodItemId, double? grams}) =>
      MealEntry(
        foodItemId: foodItemId ?? this.foodItemId,
        grams: grams ?? this.grams,
      );
}

/// План питания на всю неделю
@HiveType(typeId: AppConstants.mealPlanTypeId)
class MealPlanModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  /// Ключ: 'weekday_mealType' (например '0_breakfast' = ПН завтрак)
  /// Значение: список продуктов
  @HiveField(2)
  Map<String, List<MealEntry>> entries;

  /// Дневная норма калорий (для прогресс-бара)
  @HiveField(3)
  double dailyCalorieTarget;

  /// Дневная норма белков (г)
  @HiveField(4)
  double dailyProteinTarget;

  /// Дневная норма жиров (г)
  @HiveField(5)
  double dailyFatTarget;

  /// Дневная норма углеводов (г)
  @HiveField(6)
  double dailyCarbTarget;

  @HiveField(7)
  DateTime createdAt;

  MealPlanModel({
    required this.id,
    required this.name,
    Map<String, List<MealEntry>>? entries,
    this.dailyCalorieTarget = 2000,
    this.dailyProteinTarget = 150,
    this.dailyFatTarget = 60,
    this.dailyCarbTarget = 200,
    DateTime? createdAt,
  })  : entries = entries ?? {},
        createdAt = createdAt ?? DateTime.now();

  static String entryKey(int weekday, MealType meal) =>
      '${weekday}_${meal.name}';

  List<MealEntry> getEntries(int weekday, MealType meal) =>
      entries[entryKey(weekday, meal)] ?? [];

  MealPlanModel copyWith({
    String? id,
    String? name,
    Map<String, List<MealEntry>>? entries,
    double? dailyCalorieTarget,
    double? dailyProteinTarget,
    double? dailyFatTarget,
    double? dailyCarbTarget,
  }) =>
      MealPlanModel(
        id: id ?? this.id,
        name: name ?? this.name,
        entries: entries ?? Map.from(this.entries),
        dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
        dailyProteinTarget: dailyProteinTarget ?? this.dailyProteinTarget,
        dailyFatTarget: dailyFatTarget ?? this.dailyFatTarget,
        dailyCarbTarget: dailyCarbTarget ?? this.dailyCarbTarget,
        createdAt: createdAt,
      );
}
