import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/food_item_model.dart';
import '../../controllers/food_item_controller.dart';
import '../../widgets/food_item_card.dart';

class FoodLibraryScreen extends StatelessWidget {
  const FoodLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<FoodItemController>();
    final args = Get.arguments;
    final selectionMode = args is Map && args['selectionMode'] == true;

    // Reset multi-select when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      c.exitSelectionMode();
    });

    return Obx(() {
      final inSelectMode = c.selectionMode.value;
      final selectedCount = c.selectedIds.length;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: inSelectMode
              ? IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textPrimary),
                  onPressed: c.exitSelectionMode,
                )
              : null,
          title: inSelectMode
              ? Text('Выбрано: $selectedCount',
                  style: const TextStyle(color: AppColors.textPrimary))
              : Text(selectionMode ? 'Выбрать продукт' : 'Библиотека продуктов'),
          actions: inSelectMode
              ? [
                  // Select all
                  IconButton(
                    icon: const Icon(Icons.select_all, color: AppColors.textSecondary),
                    tooltip: 'Выбрать все',
                    onPressed: c.selectAll,
                  ),
                ]
              : [
                  // Toggle show hidden
                  Obx(() => IconButton(
                    icon: Icon(
                      c.showHidden.value ? Icons.visibility_off : Icons.visibility,
                      color: c.showHidden.value ? AppColors.textSecondary : AppColors.textHint,
                    ),
                    tooltip: c.showHidden.value ? 'Скрыть скрытые' : 'Показать скрытые',
                    onPressed: c.toggleShowHidden,
                  )),
                ],
          bottom: inSelectMode
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      onChanged: c.setSearch,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Поиск по названию...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.textHint, size: 20),
                        suffixIcon: Obx(() => c.searchQuery.value.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, color: AppColors.textHint, size: 18),
                                onPressed: () => c.setSearch(''),
                              )
                            : const SizedBox.shrink()),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
        ),
        body: Column(
          children: [
            // Selection action bar
            if (inSelectMode)
              _SelectionActionBar(c: c),
            // Grid
            Expanded(
              child: Obx(() {
                final items = c.filteredItems;
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🍽️', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        Text(
                          c.searchQuery.value.isNotEmpty ? 'Ничего не найдено' : 'Библиотека пуста',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                        ),
                        if (c.searchQuery.value.isEmpty) ...[
                          const SizedBox(height: 8),
                          const Text('Добавьте первый продукт',
                              style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                        ],
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Obx(() {
                      final isSelected = c.selectedIds.contains(item.id);
                      return _SelectableFoodCard(
                        item: item,
                        isSelected: isSelected,
                        inSelectMode: c.selectionMode.value,
                        selectionModeArg: selectionMode,
                        onTap: () {
                          if (c.selectionMode.value) {
                            c.toggleSelection(item.id);
                          } else if (selectionMode) {
                            Get.back(result: item.id);
                          } else {
                            Get.toNamed(AppRoutes.foodDetail, arguments: item);
                          }
                        },
                        onLongPress: () {
                          if (!selectionMode) {
                            c.enterSelectionMode(item.id);
                          }
                        },
                      );
                    });
                  },
                );
              }),
            ),
          ],
        ),
        floatingActionButton: Obx(() => c.selectionMode.value
            ? const SizedBox.shrink()
            : selectionMode
                ? FloatingActionButton.extended(
                    onPressed: () async {
                      final newItem = c.createEmpty();
                      final result = await Get.toNamed(AppRoutes.foodCreate, arguments: newItem);
                      if (result is String) Get.back(result: result);
                    },
                    backgroundColor: AppColors.surfaceVariant,
                    icon: const Icon(Icons.add, color: AppColors.textPrimary),
                    label: const Text('Новый продукт', style: TextStyle(color: AppColors.textPrimary)),
                  )
                : FloatingActionButton(
                    onPressed: () {
                      final newItem = c.createEmpty();
                      Get.toNamed(AppRoutes.foodCreate, arguments: newItem);
                    },
                    backgroundColor: AppColors.surfaceVariant,
                    child: const Icon(Icons.add, color: AppColors.textPrimary),
                  )),
      );
    });
  }
}

// ─── Selection action bar ─────────────────────────────────────────────────────

class _SelectionActionBar extends StatelessWidget {
  final FoodItemController c;
  const _SelectionActionBar({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedIds = c.selectedIds;
      final hasHidden = selectedIds.any((id) {
        final item = c.allItems.firstWhereOrNull((f) => f.id == id);
        return item?.isHidden ?? false;
      });
      final hasVisible = selectedIds.any((id) {
        final item = c.allItems.firstWhereOrNull((f) => f.id == id);
        return !(item?.isHidden ?? true);
      });

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Hide
            if (hasVisible)
              Expanded(
                child: _ActionBtn(
                  icon: Icons.visibility_off_outlined,
                  label: 'Скрыть',
                  onTap: () => _confirmHide(context, c),
                ),
              ),
            if (hasVisible && hasHidden) const SizedBox(width: 8),
            // Unhide
            if (hasHidden)
              Expanded(
                child: _ActionBtn(
                  icon: Icons.visibility_outlined,
                  label: 'Показать',
                  onTap: c.unhideSelected,
                ),
              ),
            const SizedBox(width: 8),
            // Delete
            Expanded(
              child: _ActionBtn(
                icon: Icons.delete_outline,
                label: 'Удалить',
                color: const Color(0xFFEF5350),
                onTap: () => _confirmDelete(context, c),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _confirmHide(BuildContext context, FoodItemController c) {
    Get.dialog(AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
      title: const Text('Скрыть продукты?', style: TextStyle(color: AppColors.textPrimary, fontSize: 15)),
      content: const Text(
        'Скрытые продукты не будут отображаться в плане питания и при привязке к задачам.\nМожно восстановить через кнопку "Показать скрытые".',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Отмена', style: TextStyle(color: AppColors.textHint))),
        TextButton(
          onPressed: () { Get.back(); c.hideSelected(); },
          child: const Text('Скрыть', style: TextStyle(color: AppColors.textPrimary)),
        ),
      ],
    ));
  }

  void _confirmDelete(BuildContext context, FoodItemController c) {
    final count = c.selectedIds.length;
    Get.dialog(AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
      title: Text('Удалить ${count == 1 ? "продукт" : "$count продукта(ов)"}?',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
      content: const Text('Это действие нельзя отменить.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Отмена', style: TextStyle(color: AppColors.textHint))),
        TextButton(
          onPressed: () { Get.back(); c.deleteSelected(); },
          child: const Text('Удалить', style: TextStyle(color: Color(0xFFEF5350))),
        ),
      ],
    ));
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _ActionBtn({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: c, size: 18),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: c, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ─── Selectable food card wrapper ─────────────────────────────────────────────

class _SelectableFoodCard extends StatelessWidget {
  final FoodItemModel item;
  final bool isSelected;
  final bool inSelectMode;
  final bool selectionModeArg;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SelectableFoodCard({
    required this.item,
    required this.isSelected,
    required this.inSelectMode,
    required this.selectionModeArg,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.textSecondary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Opacity(
              opacity: item.isHidden ? 0.45 : 1.0,
              child: FoodItemCard(
                item: item,
                selectable: selectionModeArg,
                onTap: onTap,
              ),
            ),
          ),
        ),
        // Checkbox overlay
        if (inSelectMode)
          Positioned(
            top: 6,
            right: 6,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.textSecondary : AppColors.surfaceVariant,
                border: Border.all(
                  color: isSelected ? AppColors.textSecondary : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: AppColors.textPrimary, size: 13)
                  : null,
            ),
          ),
        // Hidden badge
        if (item.isHidden)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text('скрыт', style: TextStyle(color: AppColors.textHint, fontSize: 9)),
            ),
          ),
      ],
    );
  }
}
