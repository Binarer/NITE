import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nite/core/routes/AppRoutes/app_routes.dart';
import 'package:nite/core/theme/AppTheme/app_theme.dart';
import 'package:nite/presentation/controllers/HomeController/home_controller.dart';
import 'package:nite/presentation/controllers/SettingsController/settings_controller.dart';
import 'package:nite/presentation/controllers/TagController/tag_controller.dart';
import 'package:nite/presentation/controllers/TaskController/task_controller.dart';
import 'package:nite/presentation/widgets/AppSidebar/app_sidebar.dart';
import 'package:nite/presentation/widgets/common/WeekDayColumn/week_day_column.dart';
import 'package:nite/presentation/widgets/task/TaskCard/task_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ScrollController _scrollController;
  late HomeController _homeController;
  late TaskController _taskController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const double _columnWidth = 160.0;

  @override
  void initState() {
    super.initState();
    _homeController = Get.find<HomeController>();
    _taskController = Get.find<TaskController>();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    final weekdays = _homeController.weekDays;
    final now = DateTime.now();
    final todayIndex = weekdays.indexWhere((d) =>
        d.year == now.year && d.month == now.month && d.day == now.day);
    if (todayIndex < 0) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final offset =
        (_columnWidth * todayIndex) - (screenWidth / 2) + (_columnWidth / 2);
    _scrollController.animateTo(
      offset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  void _openMenu() => _scaffoldKey.currentState?.openDrawer();
  void _openMenuEnd() => _scaffoldKey.currentState?.openEndDrawer();

  @override
  Widget build(BuildContext context) {
    final settingsCtrl = Get.find<SettingsController>();
    return Obx(() {
      final menuSide = settingsCtrl.menuSide.value;
      final drawer = const AppSidebar();
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        drawer: menuSide == 'left' ? drawer : null,
        endDrawer: menuSide == 'right' ? drawer : null,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(menuSide),
              _buildWeekNavigator(),
              _buildTagFilter(),
              Expanded(
                child: Obx(() {
                  final mode = _homeController.viewMode.value;
                  if (mode == ViewMode.day) {
                    return _buildDayView();
                  }
                  return _buildWeekView();
                }),
              ),
            ],
          ),
        ),
        floatingActionButton: Obx(() {
          final DateTime dateForTask;
          if (_homeController.viewMode.value == ViewMode.day) {
            dateForTask = _homeController.selectedDay.value;
          } else {
            final weekDays = _homeController.weekDays;
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            dateForTask =
                weekDays.any((d) => d == today) ? today : weekDays.first;
          }
          return FloatingActionButton(
            onPressed: () =>
                Get.toNamed(AppRoutes.taskCreate, arguments: dateForTask),
            backgroundColor: AppColors.surfaceVariant,
            child: const Icon(Icons.add, color: AppColors.textPrimary),
          );
        }),
      );
    });
  }

  // ignore: unused_element
  Widget _buildViewModeToggle() {
    return Obx(() {
      final mode = _homeController.viewMode.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            _ModeToggleButton(
              label: 'Неделя',
              icon: Icons.view_week_outlined,
              isSelected: mode == ViewMode.week,
              onTap: () => _homeController.setViewMode(ViewMode.week),
            ),
            const SizedBox(width: 8),
            _ModeToggleButton(
              label: 'День',
              icon: Icons.view_day_outlined,
              isSelected: mode == ViewMode.day,
              onTap: () => _homeController.setViewMode(ViewMode.day),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTagFilter() {
    return Obx(() {
      final mode = _homeController.viewMode.value;
      final tags = mode == ViewMode.day
          ? _homeController.availableTagsForDay
          : _homeController.availableTagsForWeek;
      if (tags.isEmpty) return const SizedBox.shrink();
      final selectedId = _homeController.selectedFilterTagId.value;
      return SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            // Кнопка "Все"
            _TagFilterChip(
              label: 'Все',
              emoji: null,
              color: AppColors.textSecondary,
              isSelected: selectedId == null,
              onTap: () => _homeController.setTagFilter(null),
            ),
            ...tags.map((tag) => Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _TagFilterChip(
                    label: tag.name,
                    emoji: tag.emoji,
                    color: Color(tag.colorValue),
                    isSelected: selectedId == tag.id,
                    onTap: () => _homeController.setTagFilter(
                      selectedId == tag.id ? null : tag.id,
                    ),
                  ),
                )),
          ],
        ),
      );
    });
  }

  Widget _buildWeekView() {
    _homeController.currentWeekStart.value;
    _taskController.allTasks.length;
    _homeController.selectedFilterTagId.value;
    final weekDays = _homeController.weekDays;
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: SizedBox(
          width: _columnWidth * 7,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: weekDays.map((date) {
              final tasks = _homeController.getTasksForDay(date);
              return WeekDayColumn(
                key: ValueKey('${date}_${_homeController.selectedFilterTagId.value}'),
                date: date,
                tasks: tasks,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildDayView() {
    // tasksForSelectedDay реагирует на selectedDay и selectedFilterTagId
    _homeController.selectedDay.value;
    _homeController.selectedFilterTagId.value;
    _taskController.allTasks.length;
    final tasks = _homeController.tasksForSelectedDay;
    final tagController = Get.find<TagController>();
    return Column(
      children: [
        // Навигатор дня
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              _NavArrowButton(
                icon: Icons.chevron_left,
                onTap: () => _homeController.goToPreviousDay(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Center(
                  child: Text(
                    _homeController.selectedDayLabel,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _NavArrowButton(
                icon: Icons.chevron_right,
                onTap: () => _homeController.goToNextDay(),
              ),
            ],
          ),
        ),
        // Дни недели для быстрого переключения
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: _homeController.weekDays.map((date) {
              final isSelected = date == _homeController.selectedDay.value;
              final isToday = date == DateTime(
                DateTime.now().year, DateTime.now().month, DateTime.now().day);
              final weekdayNames = ['', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
              return GestureDetector(
                onTap: () => _homeController.selectDay(date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.surfaceVariant : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isToday ? AppColors.textSecondary : AppColors.border,
                      width: isToday ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        weekdayNames[date.weekday],
                        style: TextStyle(
                          color: isSelected ? AppColors.textPrimary : AppColors.textHint,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        // Список задач дня
        Expanded(
          child: tasks.isEmpty
              ? Center(
                  child: Text(
                    'Нет задач',
                    style: TextStyle(color: AppColors.textHint, fontSize: 14),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final tags = tagController.tags
                        .where((t) => task.tagIds.contains(t.id))
                        .toList();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TaskCard(
                        task: task,
                        tags: tags,
                        onTap: () => Get.toNamed(
                          AppRoutes.taskDetail,
                          arguments: task,
                        ),
                        onToggleComplete: () =>
                            _taskController.toggleComplete(task),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(String menuSide) {
    final menuButton = GestureDetector(
      onTap: menuSide == 'left' ? _openMenu : _openMenuEnd,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(Icons.menu, size: 18, color: AppColors.textSecondary),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          if (menuSide == 'left') ...[
            menuButton,
            const SizedBox(width: 12),
          ],
          Obx(() {
            final profileId = _homeController.activeProfileTagId.value;
            final tagCtrl = Get.find<TagController>();
            String title = 'NiTe';
            if (profileId != null) {
              final tag = tagCtrl.tags.firstWhereOrNull((t) => t.id == profileId);
              if (tag != null) title = '${tag.emoji} ${tag.name}';
            }
            return Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            );
          }),
          const Spacer(),
          if (menuSide == 'right') menuButton,
        ],
      ),
    );
  }

  Widget _buildWeekNavigator() {
    return Obx(() {
      if (_homeController.viewMode.value == ViewMode.day) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _NavArrowButton(
              icon: Icons.chevron_left,
              onTap: () {
                _homeController.goToPreviousWeek();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_homeController.isCurrentWeek) {
                    _scrollToToday();
                  } else {
                    _scrollController.jumpTo(0);
                  }
                });
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: _homeController.isCurrentWeek
                    ? null
                    : () {
                        _homeController.goToCurrentWeek();
                        WidgetsBinding.instance
                            .addPostFrameCallback((_) => _scrollToToday());
                      },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _homeController.weekRangeLabel,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!_homeController.isCurrentWeek)
                      const Text(
                        'вернуться к текущей',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _NavArrowButton(
              icon: Icons.chevron_right,
              onTap: () {
                _homeController.goToNextWeek();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_homeController.isCurrentWeek) {
                    _scrollToToday();
                  } else {
                    _scrollController.jumpTo(0);
                  }
                });
              },
            ),
          ],
        ),
      );
    });
  }
}

class _NavArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}

class _ModeToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeToggleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceVariant : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.textSecondary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagFilterChip extends StatelessWidget {
  final String label;
  final String? emoji;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TagFilterChip({
    required this.label,
    required this.emoji,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppColors.textSecondary,
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
