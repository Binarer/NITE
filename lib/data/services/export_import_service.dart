import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/food_item_model.dart';
import '../models/scenario_model.dart';
import '../models/subtask_model.dart';
import '../models/tag_model.dart';
import '../models/task_model.dart';
import '../repositories/food_item_repository.dart';
import '../repositories/scenario_repository.dart';
import '../repositories/tag_repository.dart';
import '../repositories/task_repository.dart';

class ExportImportService {
  static final ExportImportService _instance = ExportImportService._internal();
  factory ExportImportService() => _instance;
  ExportImportService._internal();

  // ─── Экспорт ─────────────────────────────────────────────────────────────

  Future<void> exportToJson() async {
    try {
      final data = _collectAllData();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

      final dir = await getTemporaryDirectory();
      final now = DateTime.now();
      final filename =
          'nite_backup_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.json';
      final file = File('${dir.path}/$filename');
      await file.writeAsString(jsonStr, encoding: utf8);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'NiTe — резервная копия',
      );
    } catch (e) {
      Get.snackbar(
        'Ошибка экспорта',
        e.toString(),
        backgroundColor: const Color(0xFF3A1A1A),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<ImportResult> importFromJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return ImportResult(success: false, message: 'Файл не выбран');
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString(encoding: utf8);
      final data = json.decode(content) as Map<String, dynamic>;

      return await _importData(data);
    } catch (e) {
      return ImportResult(
          success: false, message: 'Ошибка чтения файла: $e');
    }
  }

  // ─── Сбор данных ─────────────────────────────────────────────────────────

  Map<String, dynamic> _collectAllData() {
    final tagRepo = Get.find<TagRepository>();
    final taskRepo = Get.find<TaskRepository>();
    final foodRepo = Get.find<FoodItemRepository>();
    final scenarioRepo = Get.find<ScenarioRepository>();

    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'tags': tagRepo.getAll().map(_tagToJson).toList(),
      'tasks': taskRepo.getAll().map(_taskToJson).toList(),
      'foodItems': foodRepo.getAll().map(_foodToJson).toList(),
      'scenarios': scenarioRepo.getAll().map(_scenarioToJson).toList(),
    };
  }

  // ─── Сериализация ─────────────────────────────────────────────────────────

  Map<String, dynamic> _tagToJson(TagModel t) => {
        'id': t.id,
        'name': t.name,
        'emoji': t.emoji,
        'colorValue': t.colorValue,
      };

  Map<String, dynamic> _taskToJson(TaskModel t) => {
        'id': t.id,
        'name': t.name,
        'description': t.description,
        'tagIds': t.tagIds,
        'priority': t.priority,
        'useAiPriority': t.useAiPriority,
        'date': t.date.toIso8601String(),
        'startMinutes': t.startMinutes,
        'endMinutes': t.endMinutes,
        'isCompleted': t.isCompleted,
        'sortOrder': t.sortOrder,
        'scenarioId': t.scenarioId,
        'foodItemId': t.foodItemId,
        'foodItemIds': t.foodItemIds,
        'foodGrams': t.foodGrams,
        'subtasks': t.subtasks
            .map((s) => {
                  'id': s.id,
                  'title': s.title,
                  'isCompleted': s.isCompleted,
                })
            .toList(),
      };

  Map<String, dynamic> _foodToJson(FoodItemModel f) => {
        'id': f.id,
        'name': f.name,
        'description': f.description,
        'photoPath': f.photoPath,
        'calories': f.calories,
        'macros': {
          'proteins': f.macros.proteins,
          'fats': f.macros.fats,
          'carbs': f.macros.carbs,
        },
      };

  Map<String, dynamic> _scenarioToJson(ScenarioModel s) => {
        'id': s.id,
        'name': s.name,
        'tasks': s.tasks
            .map((t) => {
                  'id': t.id,
                  'name': t.name,
                  'description': t.description,
                  'tagIds': t.tagIds,
                  'priority': t.priority,
                  'weekday': t.weekday,
                  'startMinutes': t.startMinutes,
                  'endMinutes': t.endMinutes,
                })
            .toList(),
      };

  // ─── Импорт ──────────────────────────────────────────────────────────────

  Future<ImportResult> _importData(Map<String, dynamic> data) async {
    int imported = 0;
    int skipped = 0;

    try {
      final tagRepo = Get.find<TagRepository>();
      final taskRepo = Get.find<TaskRepository>();
      final foodRepo = Get.find<FoodItemRepository>();
      final scenarioRepo = Get.find<ScenarioRepository>();

      // Теги
      for (final t in (data['tags'] as List? ?? [])) {
        try {
          if (tagRepo.getById(t['id'] as String) == null) {
            await tagRepo.save(TagModel(
              id: t['id'],
              name: t['name'],
              emoji: t['emoji'] ?? '📋',
              colorValue: t['colorValue'] ?? 0xFF555555,
            ));
            imported++;
          } else {
            skipped++;
          }
        } catch (_) { skipped++; }
      }

      // Продукты питания
      for (final f in (data['foodItems'] as List? ?? [])) {
        try {
          if (foodRepo.getById(f['id'] as String) == null) {
            final m = f['macros'] as Map<String, dynamic>? ?? {};
            await foodRepo.save(FoodItemModel(
              id: f['id'],
              name: f['name'],
              description: f['description'] ?? '',
              photoPath: f['photoPath'],
              calories: (f['calories'] as num?)?.toDouble() ?? 0,
              macros: MacroNutrients(
                proteins: (m['proteins'] as num?)?.toDouble() ?? 0,
                fats: (m['fats'] as num?)?.toDouble() ?? 0,
                carbs: (m['carbs'] as num?)?.toDouble() ?? 0,
              ),
            ));
            imported++;
          } else {
            skipped++;
          }
        } catch (_) { skipped++; }
      }

      // Сценарии
      for (final s in (data['scenarios'] as List? ?? [])) {
        try {
          if (scenarioRepo.getById(s['id'] as String) == null) {
            final tasks = (s['tasks'] as List? ?? [])
                .map((t) => ScenarioTask(
                      id: t['id'],
                      name: t['name'],
                      description: t['description'] ?? '',
                      tagIds: List<String>.from(t['tagIds'] ?? []),
                      priority: t['priority'] ?? 0,
                      weekday: t['weekday'] ?? 0,
                      startMinutes: t['startMinutes'],
                      endMinutes: t['endMinutes'],
                    ))
                .toList();
            await scenarioRepo.save(
                ScenarioModel(id: s['id'], name: s['name'], tasks: tasks));
            imported++;
          } else {
            skipped++;
          }
        } catch (_) { skipped++; }
      }

      // Задачи
      for (final t in (data['tasks'] as List? ?? [])) {
        try {
          if (taskRepo.getById(t['id'] as String) == null) {
            final subtasksList = (t['subtasks'] as List? ?? [])
                .map((s) => SubtaskModel(
                      id: s['id'] ?? '',
                      title: s['title'] ?? '',
                      isCompleted: s['isCompleted'] ?? false,
                    ))
                .toList();
            await taskRepo.save(TaskModel(
              id: t['id'],
              name: t['name'],
              description: t['description'] ?? '',
              tagIds: List<String>.from(t['tagIds'] ?? []),
              priority: t['priority'] ?? 0,
              useAiPriority: t['useAiPriority'] ?? false,
              date: DateTime.parse(t['date']),
              startMinutes: t['startMinutes'],
              endMinutes: t['endMinutes'],
              isCompleted: t['isCompleted'] ?? false,
              sortOrder: t['sortOrder'] ?? 0,
              scenarioId: t['scenarioId'],
              foodItemId: t['foodItemId'],
              foodItemIds: List<String>.from(t['foodItemIds'] ?? []),
              foodGrams: (t['foodGrams'] as num?)?.toDouble() ?? 100.0,
              subtasks: subtasksList,
            ));
            imported++;
          } else {
            skipped++;
          }
        } catch (_) { skipped++; }
      }

      return ImportResult(
        success: true,
        message: 'Импортировано: $imported, пропущено: $skipped',
        imported: imported,
        skipped: skipped,
      );
    } catch (e) {
      return ImportResult(success: false, message: 'Ошибка импорта: $e');
    }
  }
}

class ImportResult {
  final bool success;
  final String message;
  final int imported;
  final int skipped;

  ImportResult({
    required this.success,
    required this.message,
    this.imported = 0,
    this.skipped = 0,
  });
}
