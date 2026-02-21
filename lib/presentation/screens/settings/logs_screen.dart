import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_logger.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final ScrollController _scroll = ScrollController();
  bool _autoScroll = true;
  LogLevel? _filter; // null = все уровни

  @override
  void initState() {
    super.initState();
    // Слушаем новые записи и прокручиваем вниз если включён автоскролл
    ever(log.entries, (_) {
      if (_autoScroll && _scroll.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) {
            _scroll.animateTo(
              _scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    // Прокрутить вниз при открытии
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  List<LogEntry> get _filtered {
    if (_filter == null) return log.entries.toList();
    return log.entries.where((e) => e.level == _filter).toList();
  }

  void _copyAll() {
    final text = _filtered
        .map((e) => '[${e.timeLabel}][${e.level.name}][${e.tag}] ${e.message}')
        .join('\n');
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Скопировано',
      'Логи скопированы в буфер обмена',
      backgroundColor: const Color(0xFF1E1E1E),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Логи'),
        actions: [
          // Фильтр по уровню
          PopupMenuButton<LogLevel?>(
            icon: const Icon(Icons.filter_list, color: AppColors.textSecondary),
            color: AppColors.surfaceVariant,
            tooltip: 'Фильтр',
            onSelected: (v) => setState(() => _filter = v),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: null,
                child: Text('Все', style: TextStyle(color: AppColors.textPrimary)),
              ),
              const PopupMenuItem(
                value: LogLevel.info,
                child: Text('ℹ️  Info', style: TextStyle(color: AppColors.textPrimary)),
              ),
              const PopupMenuItem(
                value: LogLevel.success,
                child: Text('✅ Success', style: TextStyle(color: AppColors.textPrimary)),
              ),
              const PopupMenuItem(
                value: LogLevel.warning,
                child: Text('⚠️  Warning', style: TextStyle(color: AppColors.textPrimary)),
              ),
              const PopupMenuItem(
                value: LogLevel.error,
                child: Text('❌ Error', style: TextStyle(color: AppColors.textPrimary)),
              ),
            ],
          ),
          // Автоскролл
          IconButton(
            tooltip: _autoScroll ? 'Автоскролл вкл' : 'Автоскролл выкл',
            icon: Icon(
              Icons.vertical_align_bottom,
              color: _autoScroll ? AppColors.textPrimary : AppColors.textHint,
            ),
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
          ),
          // Копировать
          IconButton(
            tooltip: 'Копировать все',
            icon: const Icon(Icons.copy, color: AppColors.textSecondary),
            onPressed: _copyAll,
          ),
          // Очистить
          IconButton(
            tooltip: 'Очистить',
            icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary),
            onPressed: () {
              log.clear();
              Get.snackbar(
                'Очищено',
                'Журнал логов очищен',
                backgroundColor: const Color(0xFF1E1E1E),
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 1),
              );
            },
          ),
        ],
      ),
      body: Obx(() {
        final items = _filtered;
        if (items.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('📋', style: TextStyle(fontSize: 40)),
                SizedBox(height: 12),
                Text(
                  'Логов пока нет',
                  style: TextStyle(color: AppColors.textHint, fontSize: 14),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: items.length,
          itemBuilder: (_, i) => _LogRow(entry: items[i]),
        );
      }),
      // Плашка фильтра
      bottomNavigationBar: _filter != null
          ? Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Фильтр: ${_filter!.name}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _filter = null),
                    child: const Text(
                      'Сбросить',
                      style: TextStyle(color: AppColors.textHint, fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

class _LogRow extends StatelessWidget {
  final LogEntry entry;
  const _LogRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(
          ClipboardData(
            text: '[${entry.timeLabel}][${entry.level.name}][${entry.tag}] ${entry.message}',
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Строка скопирована'),
            duration: Duration(seconds: 1),
            backgroundColor: Color(0xFF2A2A2A),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Время
            Text(
              entry.timeLabel,
              style: const TextStyle(
                color: AppColors.textHint,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 6),
            // Эмодзи уровня
            Text(entry.levelEmoji, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
            // Тег
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                entry.tag,
                style: TextStyle(
                  color: entry.levelColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Сообщение
            Expanded(
              child: Text(
                entry.message,
                style: TextStyle(
                  color: entry.levelColor,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
