import 'package:hive/hive.dart';
import '../../../core/constants/AppConstants/app_constants.dart';
import '../MealPlanModel/meal_plan_model.dart';


part 'daily_meal_log_model.g.dart';

/// Запись фактического потребления за конкретный день.
/// Создаётся автоматически при выполнении задач с тегом «Еда» или вручную.
@HiveType(typeId: AppConstants.dailyMealLogTypeId)
class DailyMealLog extends HiveObject {
  @HiveField(0)
  String id;   // UUID

  /// Дата (без времени — только год/месяц/день)
  @HiveField(1)
  DateTime date;

  /// Ключ: mealType.name (breakfast/lunch/dinner/snack)
  /// Значение: список продуктов (MealEntry)
  @HiveField(2)
  Map<String, List<MealEntry>> entries;

  /// Заметка за день (опционально)
  @HiveField(3)
  String? note;

  DailyMealLog({
    required this.id,
    required this.date,
    Map<String, List<MealEntry>>? entries,
    this.note,
  }) : entries = entries ?? {};

  /// Возвращает записи для конкретного приёма пищи
  List<MealEntry> getEntries(MealType meal) =>
      entries[meal.name] ?? [];

  /// Добавляет или обновляет записи для конкретного приёма пищи
  void setEntries(MealType meal, List<MealEntry> items) {
    entries[meal.name] = items;
  }

  /// Все записи за день (плоский список)
  List<MealEntry> get allEntries =>
      entries.values.expand((e) => e).toList();

  DailyMealLog copyWith({
    String? id,
    DateTime? date,
    Map<String, List<MealEntry>>? entries,
    String? note,
  }) =>
      DailyMealLog(
        id: id ?? this.id,
        date: date ?? this.date,
        entries: entries ?? Map.from(this.entries),
        note: note,
      );
}
