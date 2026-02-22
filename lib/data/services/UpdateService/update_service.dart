import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/AppTheme/app_theme.dart';
import '../../../core/utils/AppLogger/app_logger.dart';
import 'package:url_launcher/url_launcher.dart';


class UpdateService {
  static const _owner = 'Binarer';
  static const _repo = 'NITE';
  static const _apiUrl = 'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  /// Текущая версия приложения (должна совпадать с pubspec.yaml)
  static const String currentVersion = '1.2.2';

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    headers: {'Accept': 'application/vnd.github+json'},
  ));

  /// Проверяет GitHub Releases. Если есть новая версия — показывает диалог.
  Future<void> checkForUpdate({bool silent = true}) async {
    try {
      final response = await _dio.get(_apiUrl);
      if (response.statusCode != 200) return;

      final data = response.data as Map<String, dynamic>;
      final tagName = (data['tag_name'] as String?)?.replaceFirst('v', '') ?? '';
      final body = (data['body'] as String?) ?? '';
      final htmlUrl = (data['html_url'] as String?) ?? '';

      // Найти APK asset для arm64 (наиболее распространённый)
      final assets = (data['assets'] as List<dynamic>?) ?? [];
      final arm64Asset = assets.firstWhereOrNull(
        (a) => (a['name'] as String).contains('arm64'),
      );
      final downloadUrl = arm64Asset != null
          ? arm64Asset['browser_download_url'] as String
          : htmlUrl;

      if (_isNewer(tagName, currentVersion)) {
        log.info('UpdateService', 'Доступна версия $tagName (текущая $currentVersion)');
        _showUpdateDialog(tagName, body, downloadUrl, htmlUrl);
      } else {
        if (!silent) {
          Get.snackbar(
            'Обновлений нет',
            'У вас актуальная версия NiTe ($currentVersion)',
            backgroundColor: AppColors.surface,
            colorText: AppColors.textSecondary,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        }
        log.info('UpdateService', 'Версия актуальна ($currentVersion)');
      }
    } catch (e) {
      if (!silent) {
        log.warning('UpdateService', 'Не удалось проверить обновления: $e');
      }
    }
  }

  /// Сравнивает версии вида "1.2.1"
  bool _isNewer(String remote, String current) {
    try {
      final r = remote.split('.').map(int.parse).toList();
      final c = current.split('.').map(int.parse).toList();
      for (int i = 0; i < 3; i++) {
        final rv = i < r.length ? r[i] : 0;
        final cv = i < c.length ? c[i] : 0;
        if (rv > cv) return true;
        if (rv < cv) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void _showUpdateDialog(String version, String changelog, String downloadUrl, String releaseUrl) {
    if (Get.isBottomSheetOpen == true || Get.isDialogOpen == true) return;
    Get.bottomSheet(
      _UpdateBottomSheet(
        version: version,
        changelog: changelog,
        downloadUrl: downloadUrl,
        releaseUrl: releaseUrl,
      ),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
    );
  }
}

// ─── Bottom sheet обновления ──────────────────────────────────────────────────

class _UpdateBottomSheet extends StatelessWidget {
  final String version;
  final String changelog;
  final String downloadUrl;
  final String releaseUrl;

  const _UpdateBottomSheet({
    required this.version,
    required this.changelog,
    required this.downloadUrl,
    required this.releaseUrl,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight / 3,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AppColors.border),
          left: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Заголовок
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(
              children: [
                const Text('🚀', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Доступно обновление',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Версия $version',
                        style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: Get.back,
                  icon: const Icon(Icons.close, color: AppColors.textHint, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Divider(color: AppColors.border, height: 1),
          ),
          // Changelog
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                changelog.isNotEmpty ? changelog : 'Смотрите детали на странице релиза.',
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ),
          // Кнопки
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Get.back();
                      launchUrl(Uri.parse(releaseUrl),
                          mode: LaunchMode.externalApplication);
                    },
                    child: const Text('Релиз'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceVariant,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Get.back();
                      launchUrl(Uri.parse(downloadUrl),
                          mode: LaunchMode.externalApplication);
                    },
                    child: const Text('⬇ Скачать APK'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
