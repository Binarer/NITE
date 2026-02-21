import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/subtask_model.dart';
import '../../data/models/tag_model.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/tag_repository.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/settings_service.dart';
import 'task_controller.dart';

class TaskFormController extends GetxController {
  final TaskController _taskController = Get.find<TaskController>();
  final SettingsService _settings = Get.find<SettingsService>();

  // Редактируемая задача (null = создание новой)
  TaskModel? editingTask;

  // Форма
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  final RxList<String> selectedTagIds = <String>[].obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxnInt startMinutes = RxnInt();
  final RxnInt endMinutes = RxnInt();
  final RxInt priority = 0.obs;
  final RxBool useAiPriority = false.obs;
  final RxnString foodItemId = RxnString(); // оставлен для совместимости
  final RxList<String> foodItemIds = <String>[].obs;
  /// Граммы для каждого продукта: id → граммы (по умолчанию 100г)
  final RxMap<String, double> foodItemGrams = <String, double>{}.obs;

  final RxList<Map<String, dynamic>> subtasks = <Map<String, dynamic>>[].obs;
  // формат: {'id': String, 'title': String, 'isCompleted': bool}

  final RxBool isLoading = false.obs;
  final RxBool hasInternet = false.obs;

  Timer? _connectivityTimer;

  @override
  void onInit() {
    super.onInit();
    _checkConnectivity();
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkConnectivity(),
    );
    final args = Get.arguments;
    if (args is TaskModel) {
      _loadTask(args);
    } else if (args is DateTime) {
      selectedDate.value = args;
    }
  }

  void _loadTask(TaskModel task) {
    editingTask = task;
    nameController.text = task.name;
    descriptionController.text = task.description;
    selectedTagIds.value = List<String>.from(task.tagIds);
    selectedDate.value = task.date;
    startMinutes.value = task.startMinutes;
    endMinutes.value = task.endMinutes;
    priority.value = task.priority;
    useAiPriority.value = task.useAiPriority;
    foodItemId.value = task.foodItemId;
    // Загружаем список продуктов: сначала из foodItemIds, иначе из старого foodItemId
    if (task.foodItemIds.isNotEmpty) {
      foodItemIds.value = List<String>.from(task.foodItemIds);
    } else if (task.foodItemId != null) {
      foodItemIds.value = [task.foodItemId!];
    } else {
      foodItemIds.clear();
    }
    // Граммы: для первого продукта берём из foodGrams (обратная совместимость)
    foodItemGrams.clear();
    for (final id in foodItemIds) {
      foodItemGrams[id] = task.foodGrams > 0 ? task.foodGrams : 100.0;
    }
    // Подзадачи
    subtasks.value = task.subtasks.map((s) => <String, dynamic>{
      'id': s.id,
      'title': s.title,
      'isCompleted': s.isCompleted,
    }).toList();
  }

  void addSubtask(String title) {
    if (title.trim().isEmpty) return;
    subtasks.add(<String, dynamic>{
      'id': const Uuid().v4(),
      'title': title.trim(),
      'isCompleted': false,
    });
  }

  void removeSubtask(String id) {
    subtasks.removeWhere((s) => s['id'] == id);
  }

  void toggleSubtask(String id) {
    final index = subtasks.indexWhere((s) => s['id'] == id);
    if (index < 0) return;
    final s = subtasks[index];
    subtasks[index] = <String, dynamic>{
      'id': s['id'],
      'title': s['title'],
      'isCompleted': !(s['isCompleted'] as bool),
    };
  }

  void updateSubtaskTitle(String id, String newTitle) {
    final index = subtasks.indexWhere((s) => s['id'] == id);
    if (index < 0) return;
    final s = subtasks[index];
    subtasks[index] = <String, dynamic>{
      'id': s['id'],
      'title': newTitle.trim(),
      'isCompleted': s['isCompleted'],
    };
  }

  List<SubtaskModel> get subtaskModels => subtasks
      .map((s) => SubtaskModel(
            id: s['id'] as String,
            title: s['title'] as String,
            isCompleted: s['isCompleted'] as bool,
          ))
      .toList();

  Future<void> _checkConnectivity() async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
      ));
      // Используем нейтральный эндпоинт — не привязан к конкретному AI-провайдеру
      await dio.get('https://www.google.com');
      hasInternet.value = true;
    } on DioException catch (e) {
      // Любой HTTP-ответ означает, что интернет есть
      if (e.response != null) {
        hasInternet.value = true;
      } else {
        hasInternet.value = false;
      }
    } catch (_) {
      hasInternet.value = false;
    }
  }

  void toggleTag(String tagId) {
    if (selectedTagIds.contains(tagId)) {
      selectedTagIds.remove(tagId);
      // Если убрали тег "Еда" — снимаем привязку карточек еды
      if (tagId == TagModel.foodTagId) {
        foodItemId.value = null;
        foodItemIds.clear();
      }
    } else {
      selectedTagIds.add(tagId);
    }
  }

  bool get hasFoodTag => selectedTagIds.contains(TagModel.foodTagId);

  void setDate(DateTime date) {
    selectedDate.value = DateTime(date.year, date.month, date.day);
  }

  void setStartTime(TimeOfDay? time) {
    startMinutes.value = time != null ? time.hour * 60 + time.minute : null;
  }

  void setEndTime(TimeOfDay? time) {
    endMinutes.value = time != null ? time.hour * 60 + time.minute : null;
  }

  void setPriority(int value) {
    priority.value = value.clamp(0, 5);
  }

  void setFoodItem(String? id) {
    foodItemId.value = id;
  }

  void addFoodItem(String id) {
    if (!foodItemIds.contains(id)) {
      foodItemIds.add(id);
      foodItemGrams[id] = 100.0; // дефолт 100г
    }
  }

  void removeFoodItem(String id) {
    foodItemIds.remove(id);
    foodItemGrams.remove(id);
  }

  void setFoodItemGrams(String id, double grams) {
    foodItemGrams[id] = grams.clamp(1, 9999);
    foodItemGrams.refresh();
  }

  Future<void> deleteTask(String id) async {
    await _taskController.deleteTask(id);
  }

  Future<void> saveTask() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar(
        'Ошибка',
        'Введите название задачи',
        backgroundColor: const Color(0xFF2A2A2A),
        colorText: const Color(0xFFFFFFFF),
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;

    try {
      // AI оценка приоритета
      if (useAiPriority.value && hasInternet.value) {
        await _evaluateWithAi();
      }

      // Граммы для первого продукта (для поля foodGrams в модели)
      final firstGrams = foodItemIds.isNotEmpty
          ? (foodItemGrams[foodItemIds.first] ?? 100.0)
          : 100.0;

      if (editingTask != null) {
        final updated = editingTask!.copyWith(
          name: name,
          description: descriptionController.text.trim(),
          tagIds: List<String>.from(selectedTagIds),
          priority: priority.value,
          useAiPriority: useAiPriority.value,
          date: selectedDate.value,
          startMinutes: startMinutes.value,
          endMinutes: endMinutes.value,
          foodItemId: foodItemIds.isNotEmpty ? foodItemIds.first : null,
          foodItemIds: List<String>.from(foodItemIds),
          subtasks: subtaskModels,
          foodGrams: firstGrams,
        );
        await _taskController.saveTask(updated);
      } else {
        await _taskController.createTask(
          name: name,
          description: descriptionController.text.trim(),
          tagIds: List<String>.from(selectedTagIds),
          priority: priority.value,
          useAiPriority: useAiPriority.value,
          date: selectedDate.value,
          startMinutes: startMinutes.value,
          endMinutes: endMinutes.value,
          foodItemId: foodItemIds.isNotEmpty ? foodItemIds.first : null,
          foodItemIds: List<String>.from(foodItemIds),
          subtasks: subtaskModels,
          foodGrams: firstGrams,
        );
      }
      Get.back();
    } catch (e) {
      Get.snackbar(
        'Ошибка',
        e.toString(),
        backgroundColor: const Color(0xFF2A2A2A),
        colorText: const Color(0xFFFFFFFF),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _evaluateWithAi() async {
    final provider = _settings.aiProvider;
    final apiKey = _settings.getApiKey(provider);
    if (apiKey.isEmpty) return;

    final model = _settings.getModel(provider);
    final service = AiService(
      provider: provider,
      apiKey: apiKey,
      model: model,
    );

    // Собираем имена тегов для контекста промпта
    List<String> tagNames = [];
    try {
      final repo = Get.find<TagRepository>();
      tagNames = selectedTagIds
          .map((id) => repo.getById(id)?.name)
          .whereType<String>()
          .where((n) => n.isNotEmpty)
          .toList();
    } catch (_) {}

    String? timeInfo;
    if (startMinutes.value != null) {
      final h = (startMinutes.value! ~/ 60).toString().padLeft(2, '0');
      final m = (startMinutes.value! % 60).toString().padLeft(2, '0');
      timeInfo = '$h:$m';
      if (endMinutes.value != null) {
        final eh = (endMinutes.value! ~/ 60).toString().padLeft(2, '0');
        final em = (endMinutes.value! % 60).toString().padLeft(2, '0');
        timeInfo += ' – $eh:$em';
      }
    }

    final result = await service.estimatePriority(
      taskName: nameController.text.trim(),
      description: descriptionController.text.trim(),
      tagNames: tagNames,
      timeInfo: timeInfo,
    );
    if (result != null) {
      priority.value = result;
    }
  }

  @override
  void onClose() {
    _connectivityTimer?.cancel();
    nameController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}
