import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'food_item_model.g.dart';

@HiveType(typeId: AppConstants.macroNutrientsTypeId)
class MacroNutrients extends HiveObject {
  @HiveField(0)
  double proteins;

  @HiveField(1)
  double fats;

  @HiveField(2)
  double carbs;

  MacroNutrients({
    required this.proteins,
    required this.fats,
    required this.carbs,
  });

  MacroNutrients copyWith({
    double? proteins,
    double? fats,
    double? carbs,
  }) {
    return MacroNutrients(
      proteins: proteins ?? this.proteins,
      fats: fats ?? this.fats,
      carbs: carbs ?? this.carbs,
    );
  }
}

@HiveType(typeId: AppConstants.foodItemTypeId)
class FoodItemModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? photoPath;

  @HiveField(3)
  String description;

  @HiveField(4)
  double calories;

  @HiveField(5)
  MacroNutrients macros;

  @HiveField(6)
  bool isHidden;

  FoodItemModel({
    required this.id,
    required this.name,
    this.photoPath,
    required this.description,
    required this.calories,
    required this.macros,
    this.isHidden = false,
  });

  FoodItemModel copyWith({
    String? id,
    String? name,
    String? photoPath,
    String? description,
    double? calories,
    MacroNutrients? macros,
    bool? isHidden,
  }) {
    return FoodItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      photoPath: photoPath ?? this.photoPath,
      description: description ?? this.description,
      calories: calories ?? this.calories,
      macros: macros ?? this.macros,
      isHidden: isHidden ?? this.isHidden,
    );
  }
}
