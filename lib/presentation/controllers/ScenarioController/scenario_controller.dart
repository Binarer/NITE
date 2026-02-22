import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/ScenarioModel/scenario_model.dart';
import '../../../data/repositories/ScenarioRepository/scenario_repository.dart';
import '../TaskController/task_controller.dart';


class ScenarioController extends GetxController {
  final ScenarioRepository _repo = Get.find<ScenarioRepository>();
  final TaskController _taskController = Get.find<TaskController>();
  final _uuid = const Uuid();

  final RxList<ScenarioModel> scenarios = <ScenarioModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadScenarios();
  }

  void loadScenarios() {
    scenarios.value = _repo.getAll();
  }

  ScenarioModel? getById(String id) => _repo.getById(id);

  Future<void> saveScenario(ScenarioModel scenario) async {
    await _repo.save(scenario);
    loadScenarios();
  }

  Future<void> deleteScenario(String id) async {
    await _repo.delete(id);
    loadScenarios();
  }

  ScenarioModel createEmpty() => ScenarioModel(
        id: _uuid.v4(),
        name: '',
        tasks: [],
      );

  ScenarioTask createEmptyTask(int weekday) => ScenarioTask(
        id: _uuid.v4(),
        name: '',
        weekday: weekday,
      );

  String _taskWord(int count) {
    if (count % 100 >= 11 && count % 100 <= 14) return 'задач';
    switch (count % 10) {
      case 1: return 'задача';
      case 2: case 3: case 4: return 'задачи';
      default: return 'задач';
    }
  }

  /// Применяет сценарий на текущую или следующую неделю.
  /// [nextWeek] = false → текущая неделя, true → следующая.
  Future<int> applyScenario(ScenarioModel scenario,
      {bool nextWeek = false}) async {
    final now = DateTime.now();
    // Начало текущей недели (Понедельник)
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final weekStart = nextWeek ? monday.add(const Duration(days: 7)) : monday;

    int created = 0;
    for (final templateTask in scenario.tasks) {
      // weekday в ScenarioTask: 0=ПН, 6=ВС
      // DateTime.weekday: 1=ПН, 7=ВС
      final targetDate = weekStart.add(Duration(days: templateTask.weekday));

      await _taskController.createTask(
        name: templateTask.name,
        description: templateTask.description,
        tagIds: List<String>.from(templateTask.tagIds),
        priority: templateTask.priority,
        useAiPriority: templateTask.useAiPriority,
        date: targetDate,
        startMinutes: templateTask.startMinutes,
        endMinutes: templateTask.endMinutes,
        scenarioId: scenario.id,
        foodItemIds: List<String>.from(templateTask.foodItemIds),
        foodItemGrams: Map<String, double>.from(templateTask.foodItemGrams),
        foodItemId: templateTask.foodItemIds.isNotEmpty
            ? templateTask.foodItemIds.first
            : null,
        foodGrams: templateTask.foodItemGrams.isNotEmpty
            ? templateTask.foodItemGrams.values.first
            : 100.0,
      );
      created++;
    }
    return created;
  }

  /// Создаёт сценарий из AI-плана питания
  Future<void> createScenarioFromAiPlan({
    required String name,
    required List<dynamic> tasks,
  }) async {
    final scenario = ScenarioModel(
      id: _uuid.v4(),
      name: name,
      tasks: tasks.map((t) => ScenarioTask(
        id: _uuid.v4(),
        name: t['name'] as String,
        weekday: (t['weekday'] as int) - 1, // ScenarioTask: 0=ПН
        tagIds: List<String>.from(t['tagIds'] as List? ?? []),
        description: '',
        priority: 0,
        useAiPriority: false,
      )).toList(),
    );
    await saveScenario(scenario);
    Get.snackbar(
      'Сценарий создан',
      '"$name" добавлен в сценарии',
      backgroundColor: const Color(0xFF2A2A2A),
      colorText: const Color(0xFFFFFFFF),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Показывает диалог применения сценария и выполняет применение.
  Future<void> showApplyDialog(ScenarioModel scenario) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2E2E2E)),
        ),
        title: const Text('Применить сценарий',
            style: TextStyle(color: Color(0xFFFFFFFF))),
        content: Text(
          '"${scenario.name}"\nВыберите неделю для применения:',
          style: const TextStyle(color: Color(0xFF9E9E9E)),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Отмена',
                style: TextStyle(color: Color(0xFF5E5E5E))),
          ),
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Эта неделя',
                style: TextStyle(color: Color(0xFFFFFFFF))),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Следующая',
                style: TextStyle(color: Color(0xFF9E9E9E))),
          ),
        ],
      ),
    );
    if (result == null) return;

    final count = await applyScenario(scenario, nextWeek: result);
    final weekLabel = result ? 'следующую' : 'текущую';
    Get.snackbar(
      'Сценарий применён',
      'Создано $count ${_taskWord(count)} на $weekLabel неделю',
      backgroundColor: const Color(0xFF2A2A2A),
      colorText: const Color(0xFFFFFFFF),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }
}
