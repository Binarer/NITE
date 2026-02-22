import 'package:flutter/material.dart';
import 'package:nite/core/theme/AppTheme/app_theme.dart';

class SettingsSwitchTile extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const SettingsSwitchTile({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final tile = SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: icon != null
          ? Icon(icon, color: AppColors.textSecondary)
          : null,
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(color: AppColors.textHint, fontSize: 12),
            )
          : null,
      value: value,
      onChanged: enabled ? onChanged : null,
    );

    if (!enabled) {
      return Opacity(opacity: 0.5, child: tile);
    }

    return tile;
  }
}
