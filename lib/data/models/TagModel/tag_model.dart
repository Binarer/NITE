import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../core/constants/AppConstants/app_constants.dart';

part 'tag_model.g.dart';

@HiveType(typeId: AppConstants.tagTypeId)
class TagModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String emoji;

  @HiveField(3)
  int colorValue;

  TagModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorValue,
  });

  Color get color => Color(colorValue);

  TagModel copyWith({
    String? id,
    String? name,
    String? emoji,
    int? colorValue,
  }) {
    return TagModel(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  /// Системные теги по умолчанию
  static List<TagModel> get defaultTags => [
        TagModel(
          id: 'tag_workout',
          name: 'Тренировка',
          emoji: '💪',
          colorValue: 0xFF4CAF50,
        ),
        TagModel(
          id: 'tag_food',
          name: 'Еда',
          emoji: '🍽️',
          colorValue: 0xFFFF9800,
        ),
        TagModel(
          id: 'tag_work',
          name: 'Работа',
          emoji: '💼',
          colorValue: 0xFF2196F3,
        ),
        TagModel(
          id: 'tag_task',
          name: 'Задача',
          emoji: '✅',
          colorValue: 0xFF9C27B0,
        ),
        TagModel(
          id: 'tag_study',
          name: 'Учёба',
          emoji: '📚',
          colorValue: 0xFF00BCD4,
        ),
      ];

  static const String foodTagId = 'tag_food';
}
