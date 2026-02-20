import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/food_item_controller.dart';
import '../../widgets/food_item_card.dart';

class FoodLibraryScreen extends StatelessWidget {
  const FoodLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<FoodItemController>();
    // Режим выбора передаётся через arguments
    final args = Get.arguments;
    final selectionMode =
        args is Map && args['selectionMode'] == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(selectionMode ? 'Выбрать продукт' : 'Библиотека продуктов'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: c.setSearch,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Поиск по названию...',
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.textHint, size: 20),
                suffixIcon: Obx(() => c.searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            color: AppColors.textHint, size: 18),
                        onPressed: () {
                          c.setSearch('');
                        },
                      )
                    : const SizedBox.shrink()),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        final items = c.filteredItems;
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🍽️', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  c.searchQuery.value.isNotEmpty
                      ? 'Ничего не найдено'
                      : 'Библиотека пуста',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 16),
                ),
                if (c.searchQuery.value.isEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Добавьте первый продукт',
                    style: TextStyle(color: AppColors.textHint, fontSize: 13),
                  ),
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
            return FoodItemCard(
              item: item,
              selectable: selectionMode,
              onTap: () {
                if (selectionMode) {
                  Get.back(result: item.id);
                } else {
                  Get.toNamed(AppRoutes.foodDetail, arguments: item);
                }
              },
            );
          },
        );
      }),
      floatingActionButton: selectionMode
          ? FloatingActionButton.extended(
              onPressed: () async {
                final newItem = c.createEmpty();
                final result = await Get.toNamed(
                  AppRoutes.foodCreate,
                  arguments: newItem,
                );
                if (result is String) {
                  Get.back(result: result);
                }
              },
              backgroundColor: AppColors.surfaceVariant,
              icon: const Icon(Icons.add, color: AppColors.textPrimary),
              label: const Text('Новый продукт',
                  style: TextStyle(color: AppColors.textPrimary)),
            )
          : FloatingActionButton(
              onPressed: () {
                final newItem = c.createEmpty();
                Get.toNamed(AppRoutes.foodCreate, arguments: newItem);
              },
              backgroundColor: AppColors.surfaceVariant,
              child: const Icon(Icons.add, color: AppColors.textPrimary),
            ),
    );
  }
}
