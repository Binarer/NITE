import 'package:flutter/material.dart';
import 'package:nite/core/theme/AppTheme/app_theme.dart';


/// Универсальный секционный заголовок.
/// Заменяет копипаст Text('РАЗДЕЛ', style: TextStyle(color: AppColors.textHint, fontSize: 10, letterSpacing: 1.2))
/// в app_sidebar, settings_screen, statistics_screen, meal_plan_screen.
///
/// Пример использования:
/// ```dart
/// SectionHeader(title: 'ВИД')
/// SectionHeader(title: 'ПИТАНИЕ', trailing: IconButton(...))
/// SectionHeader.padded(title: 'ПРОФИЛЬ') // с горизонтальным паддингом
/// ```
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsets padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
  });

  /// Вариант с увеличенным вертикальным паддингом для использования внутри ListView.
  const SectionHeader.padded({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 6),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textHint,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
