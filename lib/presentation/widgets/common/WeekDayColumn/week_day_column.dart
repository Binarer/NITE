import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nite/core/constants/AppConstants/app_constants.dart';
import 'package:nite/core/routes/AppRoutes/app_routes.dart';
import 'package:nite/core/theme/AppTheme/app_theme.dart';
import 'package:nite/data/models/TaskModel/task_model.dart';
import 'package:nite/presentation/controllers/HomeController/home_controller.dart';
import 'package:nite/presentation/controllers/TagController/tag_controller.dart';
import 'package:nite/presentation/controllers/TaskController/task_controller.dart';
import 'package:nite/presentation/widgets/task/TaskCard/task_card.dart';

class WeekDayColumn extends StatelessWidget {
  final DateTime date;
  final List<TaskModel> tasks;

  const WeekDayColumn({
    super.key,
    required this.date,
    required this.tasks,
  });

  bool get _isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final tagController = Get.find<TagController>();
    final taskController = Get.find<TaskController>();
    final homeController = Get.find<HomeController>();

    // Индекс дня недели (0=ПН, 6=ВС)
    final weekdayIndex = date.weekday - 1;
    final dayName = AppConstants.weekdayNames[weekdayIndex];

    return DragTarget<TaskModel>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        final task = details.data;
        final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
        final targetDate = DateTime(date.year, date.month, date.day);
        if (taskDate != targetDate) {
          taskController.moveTaskToDate(task, date);
          homeController.taskController.loadTasks();
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 160,
          decoration: BoxDecoration(
            color: isHovering
                ? AppColors.surfaceVariant
                : AppColors.background,
            border: Border(
              right: BorderSide(color: AppColors.border, width: 0.5),
            ),
          ),
          child: Column(
            children: [
              // Заголовок дня
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.border, width: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      dayName,
                      style: TextStyle(
                        color: _isToday
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isToday
                            ? AppColors.textSecondary
                            : Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            color: _isToday
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Список задач с reorder
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Text(
                          'Нет задач',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 11,
                          ),
                        ),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.only(top: 4, bottom: 60),
                        itemCount: tasks.length,
                        onReorder: (oldIndex, newIndex) {
                          if (newIndex > oldIndex) newIndex--;
                          taskController.reorderTasksInDay(date, oldIndex, newIndex);
                        },
                        proxyDecorator: (child, index, animation) {
                          return Material(
                            color: Colors.transparent,
                            child: ScaleTransition(
                              scale: animation.drive(
                                Tween(begin: 1.0, end: 1.03).chain(
                                  CurveTween(curve: Curves.easeOut),
                                ),
                              ),
                              child: child,
                            ),
                          );
                        },
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          final tags = tagController.getByIds(task.tagIds);
                          return LongPressDraggable<TaskModel>(
                            key: ValueKey(task.id),
                            data: task,
                            delay: const Duration(milliseconds: 300),
                            feedback: Material(
                              color: Colors.transparent,
                              child: SizedBox(
                                width: 150,
                                child: Opacity(
                                  opacity: 0.85,
                                  child: TaskCard(task: task, tags: tags),
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: TaskCard(task: task, tags: tags),
                            ),
                            child: TaskCard(
                              key: ValueKey('card_${task.id}'),
                              task: task,
                              tags: tags,
                              onTap: () {
                                Get.toNamed(AppRoutes.taskDetail, arguments: task);
                              },
                              onToggleComplete: () {
                                taskController.toggleComplete(task);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
