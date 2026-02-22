import 'package:get/get.dart';
import '../../../core/utils/NutritionCalculator/nutrition_calculator.dart';
import '../../../data/repositories/FoodItemRepository/food_item_repository.dart';
import '../../../data/repositories/TaskRepository/task_repository.dart';
import '../../../data/services/SettingsService/settings_service.dart';


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
