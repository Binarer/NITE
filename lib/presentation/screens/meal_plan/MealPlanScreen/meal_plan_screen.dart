import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nite/core/constants/AppConstants/app_constants.dart';
import 'package:nite/core/theme/AppTheme/app_theme.dart';
import 'package:nite/data/models/MealPlanModel/meal_plan_model.dart';
import 'package:nite/data/repositories/FoodItemRepository/food_item_repository.dart';
import 'package:nite/data/services/SettingsService/settings_service.dart';
import 'package:nite/presentation/controllers/MealPlanController/meal_plan_controller.dart';
import 'package:nite/presentation/controllers/ScenarioController/scenario_controller.dart';
import 'package:nite/presentation/controllers/StatisticsController/statistics_controller.dart';
import 'package:nite/presentation/widgets/common/SectionHeader/section_header.dart';

class MealPlanScreen extends StatelessWidget {
  const MealPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MealPlanController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('План питания'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip: 'AI-план',
            onPressed: () => _showAiPlanDialog(context, c),
          ),
          IconButton(
            icon: const Icon(Icons.track_changes_outlined),
            tooltip: 'Нормы КБЖУ',
            onPressed: () => _showTargetsDialog(context, c),
          ),
          IconButton(
            icon: const Icon(Icons.save_alt_outlined),
            tooltip: 'Сохранить как сценарий',
            onPressed: () => _showSaveAsScenarioDialog(context, c),
          ),
        ],
      ),
      body: Obx(() {
        final weekday = c.selectedWeekday.value;
        return Column(
          children: [
            // Выбор дня недели
            _WeekdaySelector(c: c),
            // Дневной прогресс КБЖУ
            _DayProgressBar(
              macros: c.macrosForDay(weekday),
              plan: c.activePlan.value,
            ),
            const Divider(color: AppColors.border, height: 1),
            // Список блоков
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  // Недельный график калорий
                  const SectionHeader(title: 'КАЛОРИИ ЗА НЕДЕЛЮ', padding: EdgeInsets.zero),
                  const SizedBox(height: 8),
                  _WeeklyCaloriesChart(controller: c),
                  const SizedBox(height: 20),

                  // Блоки приёмов пищи текущего дня
                  SectionHeader(
                    title: 'ПРИЁМЫ ПИЩИ — ${AppConstants.weekdayNames[weekday].toUpperCase()}',
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  ...MealType.values.map((meal) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MealBlock(
                          meal: meal,
                          weekday: weekday,
                          controller: c,
                        ),
                      )),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showAiPlanDialog(BuildContext context, MealPlanController c) {
    final settings = Get.find<SettingsService>();
    final savedGoalType = settings.weightGoalType;
    String selectedGoal = savedGoalType.isNotEmpty ? savedGoalType : 'maintain';
    final statsCtrl = Get.find<StatisticsController>();
    final weightKg = statsCtrl.weightEntries.isNotEmpty
        ? statsCtrl.weightEntries.last.kg
        : null;
    final targetWeightKg = settings.targetWeightKg;
    final muscleGainKg = settings.muscleGainKg;
    final deadline = settings.weightGoalDeadline;

    Get.dialog(
      StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          title: const Row(
            children: [
              Text('🤖', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text('AI-план питания',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (weightKg == null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1A0A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF5A3A1A)),
                  ),
                  child: const Text(
                    '⚠️ Добавьте вес в разделе Статистика для точного расчёта',
                    style: TextStyle(color: Color(0xFFFFB74D), fontSize: 12),
                  ),
                )
              else
                Text(
                  'Вес: ${weightKg.toStringAsFixed(1)} кг  •  Рост: ${statsCtrl.heightCm.toStringAsFixed(0)} см',
                  style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
              if (targetWeightKg > 0 || deadline != null || muscleGainKg > 0) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1A0D),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1E3A1E)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📋 Цель из настроек',
                          style: TextStyle(color: Color(0xFF81C784), fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      if (targetWeightKg > 0)
                        Text('• Целевой вес: ${targetWeightKg.toStringAsFixed(1)} кг',
                            style: const TextStyle(color: Color(0xFF81C784), fontSize: 11)),
                      if (muscleGainKg > 0)
                        Text('• Набор мышц: ${muscleGainKg.toStringAsFixed(1)} кг',
                            style: const TextStyle(color: Color(0xFF81C784), fontSize: 11)),
                      if (deadline != null)
                        Text(
                          '• Срок: ${deadline.day}.${deadline.month.toString().padLeft(2, '0')}.${deadline.year} '
                          '(${deadline.difference(DateTime.now()).inDays} дн.)',
                          style: const TextStyle(color: Color(0xFF81C784), fontSize: 11),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text('Цель:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              ...[
                ('gain', '💪 Набор массы', '+300 ккал к TDEE'),
                ('maintain', '⚖️ Поддержание', 'Калории = TDEE'),
                ('loss', '🔥 Похудение', '-400 ккал от TDEE'),
              ].map((item) => GestureDetector(
                    onTap: () => setState(() => selectedGoal = item.$1),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: selectedGoal == item.$1
                            ? AppColors.surfaceVariant
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedGoal == item.$1
                              ? AppColors.textSecondary
                              : AppColors.border,
                          width: selectedGoal == item.$1 ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(item.$1 == selectedGoal ? '🔘' : '⬜',
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.$2,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              Text(item.$3,
                                  style: const TextStyle(
                                      color: AppColors.textHint, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 4),
              const Text(
                'AI заполнит весь недельный план из вашей библиотеки еды.',
                style: TextStyle(color: AppColors.textHint, fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Отмена',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            Obx(() => TextButton(
                  onPressed: c.isGeneratingPlan.value
                      ? null
                      : () async {
                          Get.back();
                          await c.generateAiPlan(goal: selectedGoal);
                          if (c.aiPlanError.value.isNotEmpty) {
                            Get.snackbar(
                              'Ошибка',
                              c.aiPlanError.value,
                              backgroundColor: AppColors.surface,
                              colorText: const Color(0xFFEF5350),
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          } else {
                            Get.snackbar(
                              '✅ Готово',
                              'AI-план питания создан на всю неделю',
                              backgroundColor: const Color(0xFF1A2A1A),
                              colorText: const Color(0xFF4CAF50),
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }
                        },
                  child: c.isGeneratingPlan.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.textSecondary),
                        )
                      : const Text('Создать план',
                          style: TextStyle(color: AppColors.textPrimary)),
                )),
          ],
        ),
      ),
    );
  }

  void _showTargetsDialog(BuildContext context, MealPlanController c) {
    final s = Get.find<SettingsService>();
    final kcalCtrl =
        TextEditingController(text: s.dailyCalories.toStringAsFixed(0));
    final protCtrl =
        TextEditingController(text: s.dailyProtein.toStringAsFixed(0));
    final fatCtrl =
        TextEditingController(text: s.dailyFat.toStringAsFixed(0));
    final carbCtrl =
        TextEditingController(text: s.dailyCarbs.toStringAsFixed(0));

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text('Дневные нормы',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Нормы синхронизированы с настройками приложения',
                style: TextStyle(color: AppColors.textHint, fontSize: 11),
              ),
              const SizedBox(height: 12),
              _TargetField(label: '🔥 Калории (ккал)', ctrl: kcalCtrl),
              const SizedBox(height: 10),
              _TargetField(label: '💪 Белки (г)', ctrl: protCtrl),
              const SizedBox(height: 10),
              _TargetField(label: '🥑 Жиры (г)', ctrl: fatCtrl),
              const SizedBox(height: 10),
              _TargetField(label: '🍞 Углеводы (г)', ctrl: carbCtrl),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Отмена',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              // Сохраняем в SettingsService (единый источник норм)
              await s.setDailyCalories(
                  double.tryParse(kcalCtrl.text) ?? s.dailyCalories);
              await s.setDailyProtein(
                  double.tryParse(protCtrl.text) ?? s.dailyProtein);
              await s.setDailyFat(
                  double.tryParse(fatCtrl.text) ?? s.dailyFat);
              await s.setDailyCarbs(
                  double.tryParse(carbCtrl.text) ?? s.dailyCarbs);
              Get.back();
            },
            child: const Text('Сохранить',
                style: TextStyle(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  void _showSaveAsScenarioDialog(BuildContext context, MealPlanController c) {
    final nameCtrl = TextEditingController(text: 'План питания');
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text('Сохранить как сценарий',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Все приёмы пищи будут преобразованы в задачи с тегом «Еда» и сохранены как сценарий на неделю.',
              style: TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration:
                  const InputDecoration(hintText: 'Название сценария...'),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Отмена',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final id = await c.saveAsScenario(name: name);
              if (id != null) {
                // Обновляем список сценариев
                try {
                  Get.find<ScenarioController>().loadScenarios();
                } catch (_) {}
                Get.snackbar(
                  '✅ Сценарий создан',
                  'Сценарий "$name" доступен в разделе «Сценарии»',
                  backgroundColor: const Color(0xFF1A2A1A),
                  colorText: const Color(0xFF4CAF50),
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 3),
                );
              } else {
                Get.snackbar(
                  'Нет данных',
                  'Добавьте хотя бы один продукт в план питания',
                  backgroundColor: AppColors.surface,
                  colorText: AppColors.textSecondary,
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text('Создать',
                style: TextStyle(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

// ─── Выбор дня недели ────────────────────────────────────────────────────────

class _WeekdaySelector extends StatelessWidget {
  final MealPlanController c;
  const _WeekdaySelector({required this.c});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: 7,
        itemBuilder: (ctx, i) {
          return Obx(() {
            final isSelected = c.selectedWeekday.value == i;
            // Проверяем — есть ли данные в этот день
            final hasData = MealType.values.any(
              (meal) =>
                  c.activePlan.value?.getEntries(i, meal).isNotEmpty == true,
            );
            return GestureDetector(
              onTap: () => c.selectWeekday(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.surfaceVariant
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.textSecondary
                        : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppConstants.weekdayNames[i],
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (hasData)
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }
}

// ─── Дневной прогресс КБЖУ ───────────────────────────────────────────────────

class _DayProgressBar extends StatelessWidget {
  final Map<String, double> macros;
  final MealPlanModel? plan;

  const _DayProgressBar({required this.macros, required this.plan});

  @override
  Widget build(BuildContext context) {
    final kcal = macros['kcal'] ?? 0;
    final protein = macros['protein'] ?? 0;
    final fat = macros['fat'] ?? 0;
    final carb = macros['carb'] ?? 0;

    final s = Get.find<SettingsService>();
    final targetKcal = s.dailyCalories;
    final targetProt = s.dailyProtein;
    final targetFat = s.dailyFat;
    final targetCarb = s.dailyCarbs;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: AppColors.surface,
      child: Column(
        children: [
          // Калории — главный прогресс
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${kcal.toStringAsFixed(0)} ккал',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'из ${targetKcal.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: AppColors.textHint, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _ProgressBar(
                      value: (kcal / targetKcal).clamp(0, 1),
                      color: const Color(0xFFFF9800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // БЖУ — три полоски
          Row(
            children: [
              Expanded(
                child: _MacroProgress(
                  emoji: '💪',
                  label: 'Б',
                  value: protein,
                  target: targetProt,
                  unit: 'г',
                  color: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MacroProgress(
                  emoji: '🥑',
                  label: 'Ж',
                  value: fat,
                  target: targetFat,
                  unit: 'г',
                  color: const Color(0xFFFFEB3B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MacroProgress(
                  emoji: '🍞',
                  label: 'У',
                  value: carb,
                  target: targetCarb,
                  unit: 'г',
                  color: const Color(0xFF2196F3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroProgress extends StatelessWidget {
  final String emoji;
  final String label;
  final double value;
  final double target;
  final String unit;
  final Color color;

  const _MacroProgress({
    required this.emoji,
    required this.label,
    required this.value,
    required this.target,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
            Text(
              '$label ${value.toStringAsFixed(1)}/${ target.toStringAsFixed(0)}$unit',
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 3),
        _ProgressBar(
          value: target > 0 ? (value / target).clamp(0, 1) : 0,
          color: color,
          height: 3,
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;

  const _ProgressBar({
    required this.value,
    required this.color,
    this.height = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value,
        minHeight: height,
        backgroundColor: AppColors.border,
        valueColor: AlwaysStoppedAnimation<Color>(
          value >= 1.0 ? const Color(0xFFEF5350) : color,
        ),
      ),
    );
  }
}

// ─── Блок приёма пищи ────────────────────────────────────────────────────────

class _MealBlock extends StatelessWidget {
  final MealType meal;
  final int weekday;
  final MealPlanController controller;

  const _MealBlock({
    required this.meal,
    required this.weekday,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final entries = controller.activePlan.value?.getEntries(weekday, meal) ?? [];
    final macros = controller.macrosForMeal(weekday, meal);
    final kcal = macros['kcal'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок блока
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Text(meal.emoji,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.label,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (kcal > 0)
                        Text(
                          '${kcal.toStringAsFixed(0)} ккал  •  '
                          'Б ${macros['protein']!.toStringAsFixed(1)}г  '
                          'Ж ${macros['fat']!.toStringAsFixed(1)}г  '
                          'У ${macros['carb']!.toStringAsFixed(1)}г',
                          style: const TextStyle(
                              color: AppColors.textHint, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                // Кнопка добавить продукт
                GestureDetector(
                  onTap: () => _addFood(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.add,
                        size: 16, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          // Список продуктов
          if (entries.isNotEmpty) ...[
            const Divider(color: AppColors.border, height: 1),
            ...entries.asMap().entries.map((e) {
              final idx = e.key;
              final entry = e.value;
              return _FoodEntryTile(
                entry: entry,
                index: idx,
                meal: meal,
                controller: controller,
              );
            }),
          ] else
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                'Нет продуктов. Нажмите + чтобы добавить',
                style: const TextStyle(
                    color: AppColors.textHint, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  void _addFood(BuildContext context) async {
    final result = await Get.toNamed(
      '/food',
      arguments: {'selectionMode': true},
    );
    if (result is String) {
      await controller.addEntry(
        meal,
        MealEntry(foodItemId: result, grams: 100),
      );
    }
  }
}

// ─── Плитка одного продукта в приёме пищи ───────────────────────────────────

class _FoodEntryTile extends StatefulWidget {
  final MealEntry entry;
  final int index;
  final MealType meal;
  final MealPlanController controller;

  const _FoodEntryTile({
    required this.entry,
    required this.index,
    required this.meal,
    required this.controller,
  });

  @override
  State<_FoodEntryTile> createState() => _FoodEntryTileState();
}

class _FoodEntryTileState extends State<_FoodEntryTile> {
  late TextEditingController _gramsCtrl;

  @override
  void initState() {
    super.initState();
    _gramsCtrl = TextEditingController(
      text: widget.entry.grams.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _gramsCtrl.dispose();
    super.dispose();
  }

  void _showSwapDialog(BuildContext context) {
    final similars = widget.controller
        .getSimilarFoods(widget.entry.foodItemId, widget.entry.grams);
    final foodRepo = Get.find<FoodItemRepository>();
    final current = foodRepo.getById(widget.entry.foodItemId);

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text('Заменить продукт',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15)),
        content: SizedBox(
          width: double.maxFinite,
          child: similars.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Нет похожих продуктов по КБЖУ.\nДобавьте больше продуктов в библиотеку.',
                    style: TextStyle(color: AppColors.textHint, fontSize: 13),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: similars.length,
                  separatorBuilder: (_, _) =>
                      const Divider(color: AppColors.border, height: 1),
                  itemBuilder: (ctx, i) {
                    final f = similars[i];
                    final ratio = widget.entry.grams / 100.0;
                    final kcal = f.calories * ratio;
                    final pDiff = ((f.macros.proteins - (current?.macros.proteins ?? 0)) * ratio);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      title: Text(f.name,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 13)),
                      subtitle: Text(
                        '${kcal.toStringAsFixed(0)} ккал · '
                        'Б ${(f.macros.proteins * ratio).toStringAsFixed(1)}г · '
                        'Ж ${(f.macros.fats * ratio).toStringAsFixed(1)}г · '
                        'У ${(f.macros.carbs * ratio).toStringAsFixed(1)}г',
                        style: const TextStyle(
                            color: AppColors.textHint, fontSize: 11),
                      ),
                      trailing: Text(
                        '${pDiff >= 0 ? '+' : ''}${pDiff.toStringAsFixed(1)}г Б',
                        style: TextStyle(
                          color: pDiff.abs() < 2
                              ? const Color(0xFF4CAF50)
                              : AppColors.textHint,
                          fontSize: 11,
                        ),
                      ),
                      onTap: () async {
                        Get.back();
                        await widget.controller.replaceEntry(
                          widget.meal,
                          widget.index,
                          f.id,
                          widget.entry.grams,
                        );
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Отмена',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foodRepo = Get.find<FoodItemRepository>();
    final food = foodRepo.getById(widget.entry.foodItemId);
    final ratio = widget.entry.grams / 100.0;

    final name = food?.name ?? 'Неизвестный продукт';
    final kcal = food != null ? food.calories * ratio : 0.0;
    final proteins = food != null ? food.macros.proteins * ratio : 0.0;

    return GestureDetector(
      onLongPress: () => _showSwapDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Row(
          children: [
            // Иконка + подсказка о long-press
            const Icon(Icons.drag_indicator,
                size: 16, color: AppColors.border),
            const SizedBox(width: 8),
            // Название + ккал + макронутриенты
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${kcal.toStringAsFixed(0)} ккал  ·  Б ${proteins.toStringAsFixed(1)}г',
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 11),
                  ),
                ],
              ),
            ),
            // Поле граммовки
            SizedBox(
              width: 60,
              height: 30,
              child: TextField(
                controller: _gramsCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 12),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  suffix: const Text('г',
                      style: TextStyle(
                          color: AppColors.textHint, fontSize: 10)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide:
                        const BorderSide(color: AppColors.textSecondary),
                  ),
                ),
                onSubmitted: (v) {
                  final g = double.tryParse(v);
                  if (g != null && g > 0) {
                    widget.controller
                        .updateGrams(widget.meal, widget.index, g);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            // Удалить
            GestureDetector(
              onTap: () =>
                  widget.controller.removeEntry(widget.meal, widget.index),
              child: const Icon(Icons.close,
                  size: 16, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Недельный график калорий ─────────────────────────────────────────────────

class _WeeklyCaloriesChart extends StatelessWidget {
  final MealPlanController controller;
  const _WeeklyCaloriesChart({required this.controller});

  @override
  Widget build(BuildContext context) {
    final dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final s = Get.find<SettingsService>();
    final targetKcal = s.dailyCalories;

    final dayMacros = List.generate(
        7, (i) => controller.macrosForDay(i));
    final maxKcal = dayMacros.fold(
        targetKcal, (m, d) => (d['kcal'] ?? 0) > m ? (d['kcal'] ?? 0) : m);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Цель — горизонтальная пунктирная линия
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Цель', style: TextStyle(color: AppColors.textHint, fontSize: 11)),
              Text('${targetKcal.toStringAsFixed(0)} ккал',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final kcal = dayMacros[i]['kcal'] ?? 0;
                final frac = maxKcal > 0 ? (kcal / maxKcal).clamp(0.0, 1.0) : 0.0;
                final targetFrac = maxKcal > 0 ? (targetKcal / maxKcal).clamp(0.0, 1.0) : 0.0;
                final isSelected = controller.selectedWeekday.value == i;
                final isOver = kcal > targetKcal * 1.05;
                final barColor = isOver
                    ? const Color(0xFFEF5350)
                    : isSelected
                        ? const Color(0xFF4FC3F7)
                        : AppColors.surfaceVariant;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => controller.selectWeekday(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (kcal > 0)
                            Text(
                              kcal >= 1000
                                  ? '${(kcal / 1000).toStringAsFixed(1)}k'
                                  : kcal.toStringAsFixed(0),
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textHint,
                                fontSize: 8,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              // Фон столбца
                              Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              // Линия цели
                              Positioned(
                                bottom: 80 * targetFrac - 1,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 1,
                                  color: AppColors.border,
                                ),
                              ),
                              // Столбец
                              Container(
                                height: 80 * frac,
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            dayNames[i],
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.textPrimary
                                  : AppColors.textHint,
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          // Легенда
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: const Color(0xFF4FC3F7), label: 'Выбранный день'),
              const SizedBox(width: 16),
              _LegendDot(color: const Color(0xFFEF5350), label: 'Перебор'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.border, label: 'Цель'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: AppColors.textHint, fontSize: 10)),
        ],
      );
}

// ─── Поле ввода нормы ────────────────────────────────────────────────────────

class _TargetField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;

  const _TargetField({required this.label, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ),
        SizedBox(
          width: 80,
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
