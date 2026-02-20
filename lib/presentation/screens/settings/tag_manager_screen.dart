import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/tag_model.dart';
import '../../controllers/tag_controller.dart';

class TagManagerScreen extends StatelessWidget {
  const TagManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TagController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Управление тегами')),
      body: Obx(() {
        final tags = c.tags;
        return ReorderableListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: tags.length,
          onReorder: (oldIndex, newIndex) {}, // теги не требуют порядка
          itemBuilder: (context, index) {
            final tag = tags[index];
            return _TagTile(
              key: ValueKey(tag.id),
              tag: tag,
              onEdit: () => _showTagDialog(context, c, tag: tag),
              onDelete: () => _confirmDelete(c, tag),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTagDialog(context, c),
        backgroundColor: AppColors.surfaceVariant,
        child: const Icon(Icons.add, color: AppColors.textPrimary),
      ),
    );
  }

  Future<void> _showTagDialog(BuildContext context, TagController c,
      {TagModel? tag}) async {
    await Get.dialog(
      _TagDialog(
        tag: tag,
        onSave: (saved) async {
          await c.saveTag(saved);
          Get.back();
        },
      ),
    );
  }

  Future<void> _confirmDelete(TagController c, TagModel tag) async {
    final confirm = await Get.dialog<bool>(AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      title: const Text('Удалить тег?',
          style: TextStyle(color: AppColors.textPrimary)),
      content: Text(
        'Тег "${tag.emoji} ${tag.name}" будет удалён.',
        style: const TextStyle(color: AppColors.textSecondary),
      ),
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
    if (confirm == true) await c.deleteTag(tag.id);
  }
}

class _TagTile extends StatelessWidget {
  final TagModel tag;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TagTile({
    super.key,
    required this.tag,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Color(tag.colorValue).withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Color(tag.colorValue), width: 1.5),
          ),
          child: Center(
            child: Text(tag.emoji, style: const TextStyle(fontSize: 16)),
          ),
        ),
        title: Text(tag.name,
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.textSecondary),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: AppColors.textHint),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// Диалог создания/редактирования тега
class _TagDialog extends StatefulWidget {
  final TagModel? tag;
  final Future<void> Function(TagModel) onSave;

  const _TagDialog({this.tag, required this.onSave});

  @override
  State<_TagDialog> createState() => _TagDialogState();
}

class _TagDialogState extends State<_TagDialog> {
  late TextEditingController _nameCtr;
  late TextEditingController _emojiCtr;
  late int _colorValue;
  bool _isSaving = false;

  // Набор предустановленных цветов
  static const List<int> _presetColors = [
    0xFF4CAF50, 0xFF8BC34A, 0xFFCDDC39,
    0xFFFFEB3B, 0xFFFFC107, 0xFFFF9800,
    0xFFF44336, 0xFFE91E63, 0xFF9C27B0,
    0xFF673AB7, 0xFF3F51B5, 0xFF2196F3,
    0xFF03A9F4, 0xFF00BCD4, 0xFF009688,
    0xFF607D8B, 0xFF9E9E9E, 0xFFFFFFFF,
  ];

  @override
  void initState() {
    super.initState();
    _nameCtr = TextEditingController(text: widget.tag?.name ?? '');
    _emojiCtr = TextEditingController(text: widget.tag?.emoji ?? '');
    _colorValue = widget.tag?.colorValue ?? _presetColors[9];
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    _emojiCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.tag != null ? 'Редактировать тег' : 'Новый тег',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Эмодзи + предпросмотр
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(_colorValue).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Color(_colorValue), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _emojiCtr.text.isEmpty ? '?' : _emojiCtr.text,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _emojiCtr,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 18),
                    decoration: const InputDecoration(
                      hintText: 'Эмодзи',
                      hintStyle: TextStyle(fontSize: 14),
                    ),
                    maxLength: 2,
                    buildCounter: (_, {required currentLength,
                            required isFocused, maxLength}) =>
                        null,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Название
            TextField(
              controller: _nameCtr,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Название тега'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Выбор цвета
            const Text('Цвет',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetColors.map((c) {
                final isSelected = c == _colorValue;
                return GestureDetector(
                  onTap: () => setState(() => _colorValue = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.textPrimary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check,
                            size: 14, color: Colors.black)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Кнопки
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Отмена',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceVariant,
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isSaving
                      ? null
                      : () async {
                          final name = _nameCtr.text.trim();
                          final emoji = _emojiCtr.text.trim();
                          if (name.isEmpty || emoji.isEmpty) return;
                          setState(() => _isSaving = true);
                          final saved = TagModel(
                            id: widget.tag?.id ?? const Uuid().v4(),
                            name: name,
                            emoji: emoji,
                            colorValue: _colorValue,
                          );
                          await widget.onSave(saved);
                        },
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textPrimary))
                      : const Text('Сохранить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
