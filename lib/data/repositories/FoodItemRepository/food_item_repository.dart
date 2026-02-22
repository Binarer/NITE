import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/AppConstants/app_constants.dart';
import '../../models/FoodItemModel/food_item_model.dart';

class FoodItemRepository {
  Box<FoodItemModel> get _box => Hive.box<FoodItemModel>(AppConstants.foodItemsBox);

  List<FoodItemModel> getAll() => _box.values.toList();

  FoodItemModel? getById(String id) {
    try {
      return _box.values.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  List<FoodItemModel> search(String query) {
    final q = query.toLowerCase();
    return _box.values.where((f) => f.name.toLowerCase().contains(q)).toList();
  }

  Future<void> save(FoodItemModel item) async {
    await _box.put(item.id, item);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
