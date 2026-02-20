import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/food_item_model.dart';
import '../../data/repositories/food_item_repository.dart';

class FoodItemController extends GetxController {
  final FoodItemRepository _repo = Get.find<FoodItemRepository>();
  final _uuid = const Uuid();
  final _picker = ImagePicker();

  final RxList<FoodItemModel> allItems = <FoodItemModel>[].obs;
  final RxString searchQuery = ''.obs;

  List<FoodItemModel> get filteredItems {
    final q = searchQuery.value.toLowerCase();
    if (q.isEmpty) return allItems;
    return allItems.where((f) => f.name.toLowerCase().contains(q)).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadItems();
  }

  void loadItems() {
    allItems.value = _repo.getAll();
  }

  void setSearch(String query) {
    searchQuery.value = query;
  }

  FoodItemModel? getById(String id) => _repo.getById(id);

  Future<void> saveItem(FoodItemModel item) async {
    await _repo.save(item);
    loadItems();
  }

  Future<void> deleteItem(String id) async {
    // Удаляем фото с диска если есть
    final item = _repo.getById(id);
    if (item?.photoPath != null) {
      final file = File(item!.photoPath!);
      if (await file.exists()) await file.delete();
    }
    await _repo.delete(id);
    loadItems();
  }

  /// Выбирает фото из галереи, сохраняет в локальное хранилище и возвращает путь
  Future<String?> pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return _saveImageLocally(picked.path);
  }

  /// Делает фото камерой, сохраняет и возвращает путь
  Future<String?> takePhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return _saveImageLocally(picked.path);
  }

  Future<String> _saveImageLocally(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${_uuid.v4()}.jpg';
    final destPath = '${appDir.path}/food_images/$fileName';
    await Directory('${appDir.path}/food_images').create(recursive: true);
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  FoodItemModel createEmpty() => FoodItemModel(
        id: _uuid.v4(),
        name: '',
        description: '',
        calories: 0,
        macros: MacroNutrients(proteins: 0, fats: 0, carbs: 0),
      );

  /// Показывает диалог выбора источника фото
  Future<String?> showPhotoSourceDialog(BuildContext context) async {
    return await Get.bottomSheet<String>(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: Color(0xFF9E9E9E)),
              title: const Text('Выбрать из галереи',
                  style: TextStyle(color: Color(0xFFFFFFFF))),
              onTap: () => Get.back(result: 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: Color(0xFF9E9E9E)),
              title: const Text('Сделать фото',
                  style: TextStyle(color: Color(0xFFFFFFFF))),
              onTap: () => Get.back(result: 'camera'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
