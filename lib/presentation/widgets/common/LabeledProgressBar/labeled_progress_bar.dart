import 'package:flutter/material.dart';
import 'package:nite/core/theme/AppTheme/app_theme.dart';


/// Универсальный прогресс-бар с лейблом и значениями.
///
/// Заменяет повторяющийся паттерн в:
/// - meal_plan_screen.dart (_DayProgressBar: 4 строки калории+БЖУ)
/// - statistics_screen.dart (_DailyNutritionCard: аналогичные прогресс-бары)
///
/// Пример использования:
/// ```dart
/// LabeledProgressBar(
///   label: 'Калории',
///   current: 1450,
///   target: 2000,
///   color: Color(0xFFFFB300),
///   unit: 'ккал',
/// )
/// LabeledProgressBar(
///   label: 'Белки',
///   current: 85,
///   target: 150,
///   color: Color(0xFF4CAF50),
///   unit: 'г',
///   compact: true,
/// )
/// ```
class LabeledProgressBar extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;
  final String unit;

  /// compact=true — уменьшенная высота и шрифт (для БЖУ под калориями)
  final bool compact;

  /// Показывать текстовые значения справа
  final bool showValues;

  const LabeledProgressBar({
    super.key,
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    this.unit = '',
    this.compact = false,
    this.showValues = true,
  });

  double get _progress {
    if (target <= 0) return 0;
    return (current / target).clamp(0.0, 1.0);
  }

  bool get _isOver => target > 0 && current > target;

  @override
  Widget build(BuildContext context) {
    final barColor = _isOver ? const Color(0xFFF44336) : color;
    final labelSize = compact ? 11.0 : 13.0;
    final valueSize = compact ? 11.0 : 13.0;
    final barHeight = compact ? 4.0 : 6.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: labelSize,
              ),
            ),
            const Spacer(),
            if (showValues)
              Text(
                '${current.toStringAsFixed(compact ? 0 : 1)} / ${target.toStringAsFixed(0)} $unit',
                style: TextStyle(
                  color: _isOver ? const Color(0xFFF44336) : AppColors.textHint,
                  fontSize: valueSize,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(barHeight),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: barHeight,
          ),
        ),
      ],
    );
  }
}
