import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'subtask_model.g.dart';

@HiveType(typeId: AppConstants.subtaskTypeId)
class SubtaskModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool isCompleted;

  SubtaskModel({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  SubtaskModel copyWith({
    String? id,
    String? title,
    bool? isCompleted,
  }) {
    return SubtaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
