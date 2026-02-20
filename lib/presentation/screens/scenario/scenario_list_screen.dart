import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/scenario_controller.dart';

class ScenarioListScreen extends StatelessWidget {
  const ScenarioListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ScenarioController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Сценарии')),
      body: Obx(() {
        if (c.scenarios.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📋', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                const Text(
                  'Нет сценариев',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Создайте шаблон задач на неделю',
                  style:
                      TextStyle(color: AppColors.textHint, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: c.scenarios.length,
          itemBuilder: (context, index) {
            final scenario = c.scenarios[index];
            final taskCount = scenario.tasks.length;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                title: Text(
                  scenario.name.isEmpty ? 'Без названия' : scenario.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  '$taskCount ${_taskWord(taskCount)}',
                  style: const TextStyle(
                      color: AppColors.textHint, fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Применить
                    IconButton(
                      icon: const Icon(Icons.play_arrow_rounded,
                          color: AppColors.textSecondary),
                      tooltip: 'Применить',
                      onPressed: () => c.showApplyDialog(scenario),
                    ),
                    // Редактировать
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: AppColors.textSecondary, size: 20),
                      tooltip: 'Редактировать',
                      onPressed: () => Get.toNamed(
                          AppRoutes.scenarioCreate,
                          arguments: scenario),
                    ),
                  ],
                ),
                onTap: () =>
                    Get.toNamed(AppRoutes.scenarioCreate, arguments: scenario),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final newScenario = Get.find<ScenarioController>().createEmpty();
          Get.toNamed(AppRoutes.scenarioCreate, arguments: newScenario);
        },
        backgroundColor: AppColors.surfaceVariant,
        child: const Icon(Icons.add, color: AppColors.textPrimary),
      ),
    );
  }

  String _taskWord(int count) {
    if (count % 100 >= 11 && count % 100 <= 14) return 'задач';
    switch (count % 10) {
      case 1:
        return 'задача';
      case 2:
      case 3:
      case 4:
        return 'задачи';
      default:
        return 'задач';
    }
  }
}
