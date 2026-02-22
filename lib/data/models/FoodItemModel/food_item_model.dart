import 'package:hive/hive.dart';
import '../../../core/constants/AppConstants/app_constants.dart';
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

  /// Стандартная порция в граммах (по умолчанию 100г).
  /// Подставляется автоматически при добавлении продукта в задачу/план.
  @HiveField(7)
  double servingSizeGrams;

  /// Избранный продукт — показывается первым в библиотеке.
  @HiveField(8)
  bool isFavorite;

  /// Категория продукта (молочное, мясо, злаки и т.д.) — для фильтрации в библиотеке.
  @HiveField(9)
  String? category;

  FoodItemModel({
    required this.id,
    required this.name,
    this.photoPath,
    required this.description,
    required this.calories,
    required this.macros,
    this.isHidden = false,
    this.servingSizeGrams = 100.0,
    this.isFavorite = false,
    this.category,
  });

  FoodItemModel copyWith({
    String? id,
    String? name,
    String? photoPath,
    String? description,
    double? calories,
    MacroNutrients? macros,
    bool? isHidden,
    double? servingSizeGrams,
    bool? isFavorite,
    String? category,
  }) {
    return FoodItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      photoPath: photoPath ?? this.photoPath,
      description: description ?? this.description,
      calories: calories ?? this.calories,
      macros: macros ?? this.macros,
      isHidden: isHidden ?? this.isHidden,
      servingSizeGrams: servingSizeGrams ?? this.servingSizeGrams,
      isFavorite: isFavorite ?? this.isFavorite,
      category: category ?? this.category,
    );
  }
}
