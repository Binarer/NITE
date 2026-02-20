import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'scenario_model.g.dart';

/// Задача-шаблон в сценарии.
/// Привязана к дню недели (0=ПН, 6=ВС), а не к конкретной дате.
@HiveType(typeId: AppConstants.scenarioTaskTypeId)
class ScenarioTask extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  /// 0 = Понедельник, 6 = Воскресенье
  @HiveField(3)
  int weekday;

  @HiveField(4)
  List<String> tagIds;

  @HiveField(5)
  int priority;

  @HiveField(6)
  bool useAiPriority;

  /// Время начала в минутах от полуночи (null = без времени)
  @HiveField(7)
  int? startMinutes;

  /// Время конца в минутах от полуночи (null = без времени)
  @HiveField(8)
  int? endMinutes;

  ScenarioTask({
    required this.id,
    required this.name,
    this.description = '',
    required this.weekday,
    this.tagIds = const [],
    this.priority = 0,
    this.useAiPriority = false,
    this.startMinutes,
    this.endMinutes,
  });

  ScenarioTask copyWith({
    String? id,
    String? name,
    String? description,
    int? weekday,
    List<String>? tagIds,
    int? priority,
    bool? useAiPriority,
    int? startMinutes,
    int? endMinutes,
  }) {
    return ScenarioTask(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      weekday: weekday ?? this.weekday,
      tagIds: tagIds ?? this.tagIds,
      priority: priority ?? this.priority,
      useAiPriority: useAiPriority ?? this.useAiPriority,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
    );
  }
}

@HiveType(typeId: AppConstants.scenarioTypeId)
class ScenarioModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<ScenarioTask> tasks;

  ScenarioModel({
    required this.id,
    required this.name,
    this.tasks = const [],
  });

  ScenarioModel copyWith({
    String? id,
    String? name,
    List<ScenarioTask>? tasks,
  }) {
    return ScenarioModel(
      id: id ?? this.id,
      name: name ?? this.name,
      tasks: tasks ?? this.tasks,
    );
  }
}
