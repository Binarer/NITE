import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/food_item_model.dart';
import '../../controllers/food_item_controller.dart';

class FoodFormScreen extends StatefulWidget {
  const FoodFormScreen({super.key});

  @override
  State<FoodFormScreen> createState() => _FoodFormScreenState();
}

class _FoodFormScreenState extends State<FoodFormScreen> {
  late FoodItemModel _item;
  late bool _isEditing;
  final FoodItemController _c = Get.find<FoodItemController>();

  final _nameCtr = TextEditingController();
  final _descCtr = TextEditingController();
  final _calCtr = TextEditingController();
  final _protCtr = TextEditingController();
  final _fatCtr = TextEditingController();
  final _carbCtr = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is FoodItemModel) {
      _item = args;
      _isEditing = _item.name.isNotEmpty;
    } else {
      _item = _c.createEmpty();
      _isEditing = false;
    }
    _nameCtr.text = _item.name;
    _descCtr.text = _item.description;
    _calCtr.text = _item.calories > 0 ? _item.calories.toString() : '';
    _protCtr.text = _item.macros.proteins > 0 ? _item.macros.proteins.toString() : '';
    _fatCtr.text = _item.macros.fats > 0 ? _item.macros.fats.toString() : '';
    _carbCtr.text = _item.macros.carbs > 0 ? _item.macros.carbs.toString() : '';
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    _descCtr.dispose();
    _calCtr.dispose();
    _protCtr.dispose();
    _fatCtr.dispose();
    _carbCtr.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await _c.showPhotoSourceDialog(context);
    if (source == null) return;
    final path = source == 'camera'
        ? await _c.takePhoto()
        : await _c.pickPhoto();
    if (path != null) {
      setState(() => _item = _item.copyWith(photoPath: path));
    }
  }

  void _removePhoto() {
    setState(() => _item = FoodItemModel(
          id: _item.id,
          name: _item.name,
          description: _item.description,
          calories: _item.calories,
          macros: _item.macros,
          photoPath: null,
        ));
  }

  Future<void> _save() async {
    final name = _nameCtr.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Ошибка', 'Введите название продукта',
          backgroundColor: const Color(0xFF2A2A2A),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final saved = FoodItemModel(
        id: _item.id,
        name: name,
        description: _descCtr.text.trim(),
        photoPath: _item.photoPath,
        calories: double.tryParse(_calCtr.text) ?? 0,
        macros: MacroNutrients(
          proteins: double.tryParse(_protCtr.text) ?? 0,
          fats: double.tryParse(_fatCtr.text) ?? 0,
          carbs: double.tryParse(_carbCtr.text) ?? 0,
        ),
      );
      await _c.saveItem(saved);
      Get.back(result: saved.id);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await Get.dialog<bool>(AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      title: const Text('Удалить продукт?',
          style: TextStyle(color: AppColors.textPrimary)),
      content: const Text('Это действие нельзя отменить.',
          style: TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Отмена',
                style: TextStyle(color: AppColors.textSecondary))),
        TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Удалить',
                style: TextStyle(color: Color(0xFFF44336)))),
      ],
    ));
    if (confirm == true) {
      await _c.deleteItem(_item.id);
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактировать продукт' : 'Новый продукт'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.textSecondary),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Сохранить',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Фото
            _buildPhotoSection(),
            const SizedBox(height: 20),

            // Название
            _label('Название'),
            TextField(
              controller: _nameCtr,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Название продукта'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Описание
            _label('Описание'),
            TextField(
              controller: _descCtr,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Необязательно'),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Калорийность
            _label('Калорийность (ккал)'),
            TextField(
              controller: _calCtr,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: '0'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 20),

            // БЖУ
            _label('БЖУ (граммы)'),
            Row(
              children: [
                Expanded(
                    child: _macroField(_protCtr, 'Белки', const Color(0xFF4CAF50))),
                const SizedBox(width: 10),
                Expanded(
                    child: _macroField(_fatCtr, 'Жиры', const Color(0xFFFF9800))),
                const SizedBox(width: 10),
                Expanded(
                    child: _macroField(_carbCtr, 'Углеводы', const Color(0xFF2196F3))),
              ],
            ),
            const SizedBox(height: 24),

            // Кнопка удаления
            if (_isEditing) ...[
              const Divider(color: AppColors.border),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline,
                      color: Color(0xFFF44336), size: 18),
                  label: const Text('Удалить продукт',
                      style: TextStyle(color: Color(0xFFF44336))),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return GestureDetector(
      onTap: _pickPhoto,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: _item.photoPath != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.file(
                      File(_item.photoPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => _photoEmpty(),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _removePhoto,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xCC000000),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            : _photoEmpty(),
      ),
    );
  }

  Widget _photoEmpty() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.add_photo_alternate_outlined,
            size: 36, color: AppColors.textHint),
        SizedBox(height: 8),
        Text('Добавить фото',
            style: TextStyle(color: AppColors.textHint, fontSize: 13)),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8)),
    );
  }

  Widget _macroField(
      TextEditingController ctr, String hint, Color accentColor) {
    return TextField(
      controller: ctr,
      style: TextStyle(color: accentColor, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.textHint, fontSize: 12),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accentColor),
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
    );
  }
}
