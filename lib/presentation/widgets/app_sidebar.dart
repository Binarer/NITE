import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../controllers/home_controller.dart';
import '../controllers/tag_controller.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final homeCtrl = Get.find<HomeController>();
    final tagCtrl = Get.find<TagController>();

    return Container(
      width: 270,
      color: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок (фиксированный)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  const Text(
                    'NiTe',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close,
                        color: AppColors.textHint, size: 20),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),

            // Скроллируемая область
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Режим просмотра
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ВИД',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Obx(() {
                      final mode = homeCtrl.viewMode.value;
                      return Column(
                        children: [
                          _SidebarItem(
                            icon: Icons.view_week_outlined,
                            label: 'Неделя',
                            isSelected: mode == ViewMode.week,
                            onTap: () {
                              homeCtrl.setViewMode(ViewMode.week);
                              Navigator.of(context).pop();
                            },
                          ),
                          _SidebarItem(
                            icon: Icons.view_day_outlined,
                            label: 'День',
                            isSelected: mode == ViewMode.day,
                            onTap: () {
                              homeCtrl.setViewMode(ViewMode.day);
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 16),
                    const Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 12),

                    // Профили
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ПРОФИЛЬ',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Obx(() {
                      final profileId = homeCtrl.activeProfileTagId.value;
                      final tags = tagCtrl.tags;
                      return Column(
                        children: [
                          _SidebarItem(
                            icon: Icons.grid_view_rounded,
                            label: 'Все задачи',
                            isSelected: profileId == null,
                            onTap: () {
                              homeCtrl.setProfile(null);
                              Navigator.of(context).pop();
                            },
                          ),
                          ...tags.map((tag) => _SidebarItem(
                                emoji: tag.emoji,
                                label: tag.name,
                                accentColor: Color(tag.colorValue),
                                isSelected: profileId == tag.id,
                                onTap: () {
                                  homeCtrl.setProfile(tag.id);
                                  Navigator.of(context).pop();
                                },
                              )),
                        ],
                      );
                    }),

                    const SizedBox(height: 16),
                    const Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 12),

                    // Навигация
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'РАЗДЕЛЫ',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _SidebarItem(
                      icon: Icons.restaurant_menu_outlined,
                      label: 'Библиотека еды',
                      onTap: () {
                        Navigator.of(context).pop();
                        Get.toNamed(AppRoutes.foodLibrary);
                      },
                    ),
                    _SidebarItem(
                      icon: Icons.auto_awesome_mosaic_outlined,
                      label: 'Сценарии',
                      onTap: () {
                        Navigator.of(context).pop();
                        Get.toNamed(AppRoutes.scenarios);
                      },
                    ),
                    _SidebarItem(
                      icon: Icons.bar_chart_outlined,
                      label: 'Статистика',
                      onTap: () {
                        Navigator.of(context).pop();
                        Get.toNamed(AppRoutes.statistics);
                      },
                    ),
                    _SidebarItem(
                      icon: Icons.history_edu_outlined,
                      label: 'Отчёты',
                      onTap: () {
                        Navigator.of(context).pop();
                        Get.toNamed(AppRoutes.reports);
                      },
                    ),
                    _SidebarItem(
                      icon: Icons.menu_book_outlined,
                      label: 'Памятка',
                      onTap: () {
                        Navigator.of(context).pop();
                        Get.toNamed(AppRoutes.help);
                      },
                    ),
                    _SidebarItem(
                      icon: Icons.settings_outlined,
                      label: 'Настройки',
                      onTap: () {
                        Navigator.of(context).pop();
                        Get.toNamed(AppRoutes.settings);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final String label;
  final bool isSelected;
  final Color? accentColor;
  final VoidCallback onTap;

  const _SidebarItem({
    this.icon,
    this.emoji,
    required this.label,
    this.isSelected = false,
    this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            if (emoji != null)
              Text(emoji!, style: const TextStyle(fontSize: 16))
            else
              Icon(icon,
                  size: 18,
                  color: isSelected ? color : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
