import 'package:hive_flutter/hive_flutter.dart';
import '../models/tag_model.dart';
import '../../core/constants/app_constants.dart';

class TagRepository {
  Box<TagModel> get _box => Hive.box<TagModel>(AppConstants.tagsBox);

  List<TagModel> getAll() => _box.values.toList();

  TagModel? getById(String id) {
    try {
      return _box.values.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(TagModel tag) async {
    await _box.put(tag.id, tag);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Инициализирует системные теги по умолчанию (если ещё нет)
  Future<void> initDefaultTags() async {
    if (_box.isEmpty) {
      for (final tag in TagModel.defaultTags) {
        await _box.put(tag.id, tag);
      }
    }
  }
}
