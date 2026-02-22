import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nite/core/theme/AppTheme/app_theme.dart';
import 'package:nite/presentation/controllers/StatisticsController/statistics_controller.dart';
import 'package:nite/presentation/widgets/common/SectionHeader/section_header.dart';


class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<StatisticsController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Статистика'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PeriodTab(
                    label: 'День',
                    selected: c.period.value == StatsPeriod.day,
                    onTap: () => c.setPeriod(StatsPeriod.day),
                  ),
                  const SizedBox(width: 8),
                  _PeriodTab(
                    label: 'Неделя',
                    selected: c.period.value == StatsPeriod.week,
                    onTap: () => c.setPeriod(StatsPeriod.week),
                  ),
                ],
              )),
        ),
      ),
      body: Obx(() {
        final period = c.period.value;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Навигатор даты
            _DateNavigator(controller: c),
            const SizedBox(height: 20),

            // КБЖУ секция
            SectionHeader(title: period == StatsPeriod.day ? 'КБЖУ за ${c.selectedDateLabel}' : 'КБЖУ за ${c.weekLabel}', padding: EdgeInsets.zero),
            const SizedBox(height: 8),
            period == StatsPeriod.day
                ? _DailyNutritionCard(controller: c)
                : _WeeklyNutritionChart(controller: c),
            const SizedBox(height: 24),

            // Учёт веса
            const SectionHeader(title: 'УЧЁТ ВЕСА', padding: EdgeInsets.zero),
            const SizedBox(height: 8),
            _WeightSection(controller: c),
            const SizedBox(height: 24),

            const SizedBox(height: 32),
          ],
        );
      }),
    );
  }
}

// ─── Навигатор даты ───────────────────────────────────────────────────────────

class _DateNavigator extends StatelessWidget {
  final StatisticsController controller;
  const _DateNavigator({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _NavBtn(
          icon: Icons.chevron_left,
          onTap: () {
            final d = controller.selectedDate.value;
            controller.setDate(controller.period.value == StatsPeriod.day
                ? d.subtract(const Duration(days: 1))
                : d.subtract(const Duration(days: 7)));
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: controller.selectedDate.value,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.textSecondary,
                      surface: AppColors.surface,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) controller.setDate(picked);
            },
            child: Obx(() => Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      controller.period.value == StatsPeriod.day
                          ? controller.selectedDateLabel
                          : controller.weekLabel,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )),
          ),
        ),
        const SizedBox(width: 8),
        _NavBtn(
          icon: Icons.chevron_right,
          onTap: () {
            final d = controller.selectedDate.value;
            controller.setDate(controller.period.value == StatsPeriod.day
                ? d.add(const Duration(days: 1))
                : d.add(const Duration(days: 7)));
          },
        ),
      ],
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 20, color: AppColors.textSecondary),
        ),
      );
}

// ─── Дневное КБЖУ ─────────────────────────────────────────────────────────────

class _DailyNutritionCard extends StatelessWidget {
  final StatisticsController controller;
  const _DailyNutritionCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final n = controller.dailyNutrition;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Калории — крупно
          Text(
            '${n.calories.toStringAsFixed(0)} ккал',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // БЖУ — три ячейки
          Row(
            children: [
              _MacroCell(label: 'Белки', value: n.proteins, color: const Color(0xFF4FC3F7)),
              _MacroCell(label: 'Жиры', value: n.fats, color: const Color(0xFFFFB74D)),
              _MacroCell(label: 'Углеводы', value: n.carbs, color: const Color(0xFF81C784)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroCell extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _MacroCell({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(
              '${value.toStringAsFixed(1)}г',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: AppColors.textHint, fontSize: 11),
            ),
          ],
        ),
      );
}

// ─── Недельный график КБЖУ ────────────────────────────────────────────────────

class _WeeklyNutritionChart extends StatelessWidget {
  final StatisticsController controller;
  const _WeeklyNutritionChart({required this.controller});

  @override
  Widget build(BuildContext context) {
    final days = controller.weeklyNutritionByDay;
    final total = controller.weeklyNutritionTotal;
    final maxCal = days.fold(0.0, (m, e) => e.value.calories > m ? e.value.calories : m);
    final dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return Column(
      children: [
        // Итог недели
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Text(
                '${total.calories.toStringAsFixed(0)} ккал',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text('Итого за неделю',
                  style: TextStyle(color: AppColors.textHint, fontSize: 12)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _MacroCell(label: 'Белки', value: total.proteins, color: const Color(0xFF4FC3F7)),
                  _MacroCell(label: 'Жиры', value: total.fats, color: const Color(0xFFFFB74D)),
                  _MacroCell(label: 'Углеводы', value: total.carbs, color: const Color(0xFF81C784)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Столбчатый график по дням
        Container(
          height: 160,
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final entry = days[i];
              final cal = entry.value.calories;
              final frac = maxCal > 0 ? cal / maxCal : 0.0;
              final isToday = entry.key.weekday == DateTime.now().weekday &&
                  entry.key.difference(DateTime.now()).inDays.abs() < 7;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (cal > 0)
                        Text(
                          cal.toStringAsFixed(0),
                          style: const TextStyle(
                              color: AppColors.textHint, fontSize: 8),
                        ),
                      const SizedBox(height: 2),
                      Flexible(
                        child: FractionallySizedBox(
                          heightFactor: frac.clamp(0.05, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isToday
                                  ? const Color(0xFF4FC3F7)
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dayNames[i],
                        style: TextStyle(
                          color: isToday
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                          fontSize: 11,
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ─── Учёт веса ────────────────────────────────────────────────────────────────

class _WeightSection extends StatefulWidget {
  final StatisticsController controller;
  const _WeightSection({required this.controller});

  @override
  State<_WeightSection> createState() => _WeightSectionState();
}

class _WeightSectionState extends State<_WeightSection> {
  late TextEditingController _weightCtr;

  @override
  void initState() {
    super.initState();
    final lastKg = widget.controller.weightEntries.isNotEmpty
        ? widget.controller.weightEntries.last.kg
        : 70.0;
    _weightCtr = TextEditingController(text: lastKg.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _weightCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Поле ввода + кнопка
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightCtr,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: '70.0',
                    suffixText: 'кг',
                    suffixStyle: TextStyle(color: AppColors.textHint),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceVariant,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final kg = double.tryParse(
                      _weightCtr.text.replaceAll(',', '.'));
                  if (kg != null && kg > 0) {
                    c.addWeightEntry(kg);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Вес сохранён')),
                    );
                  }
                },
                child: const Text('Сохранить'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // График весов
          Obx(() {
            final entries = c.weightEntries;
            if (entries.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Нет данных. Добавьте первое измерение.',
                    style: TextStyle(color: AppColors.textHint, fontSize: 13),
                  ),
                ),
              );
            }
            return _WeightChart(entries: entries.toList());
          }),
        ],
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  final List<WeightEntry> entries;
  const _WeightChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final minKg = entries.fold(entries.first.kg, (m, e) => e.kg < m ? e.kg : m) - 1;
    final maxKg = entries.fold(entries.first.kg, (m, e) => e.kg > m ? e.kg : m) + 1;
    const chartHeight = 120.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: chartHeight + 20,
          child: CustomPaint(
            painter: _WeightChartPainter(
              entries: entries,
              minKg: minKg,
              maxKg: maxKg,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 8),
        // Последние записи (до 5)
        ...entries.reversed.take(5).map((e) {
          final months = ['', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
              'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Text(
                  '${e.date.day} ${months[e.date.month]}',
                  style: const TextStyle(
                      color: AppColors.textHint, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  '${e.kg.toStringAsFixed(1)} кг',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  final List<WeightEntry> entries;
  final double minKg;
  final double maxKg;

  _WeightChartPainter({
    required this.entries,
    required this.minKg,
    required this.maxKg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.length < 2) {
      // Одна точка — просто рисуем точку по центру
      final paint = Paint()
        ..color = const Color(0xFF4FC3F7)
        ..strokeWidth = 3;
      canvas.drawCircle(
          Offset(size.width / 2, size.height / 2 - 10), 5, paint);
      return;
    }

    final linePaint = Paint()
      ..color = const Color(0xFF4FC3F7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = const Color(0xFF4FC3F7)
      ..style = PaintingStyle.fill;

    final range = maxKg - minKg;
    final points = entries.asMap().entries.map((e) {
      final x = e.key / (entries.length - 1) * size.width;
      final y = size.height - 20 -
          ((e.value.kg - minKg) / range) * (size.height - 30);
      return Offset(x, y);
    }).toList();

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      // Сглаживание через кривую Безье
      final prev = points[i - 1];
      final curr = points[i];
      final cp1 = Offset((prev.dx + curr.dx) / 2, prev.dy);
      final cp2 = Offset((prev.dx + curr.dx) / 2, curr.dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, curr.dx, curr.dy);
    }
    canvas.drawPath(path, linePaint);

    for (final pt in points) {
      canvas.drawCircle(pt, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_WeightChartPainter old) =>
      old.entries != entries || old.minKg != minKg || old.maxKg != maxKg;
}

// ─── Общие виджеты ────────────────────────────────────────────────────────────

class _PeriodTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PeriodTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceVariant : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.textSecondary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      );
}
