import 'package:hive/hive.dart';
import '../../../core/constants/AppConstants/app_constants.dart';
part 'ai_report_model.g.dart';

enum AiReportType { daily, weekly }

@HiveType(typeId: AppConstants.aiReportTypeId)
class AiReportModel extends HiveObject {
  @HiveField(0)
  String id;

  /// 'daily' или 'weekly'
  @HiveField(1)
  String type;

  /// Дата отчёта (для daily — конкретный день, для weekly — начало недели)
  @HiveField(2)
  DateTime date;

  /// Текст отчёта от AI
  @HiveField(3)
  String content;

  /// Когда создан (timestamp)
  @HiveField(4)
  DateTime createdAt;

  /// Snapshot: суммарные калории за период (сохраняется при генерации)
  @HiveField(5)
  double? caloriesConsumed;

  /// Snapshot: вес пользователя на момент генерации (кг)
  @HiveField(6)
  double? weightKg;

  /// Snapshot: TDEE на момент генерации (ккал)
  @HiveField(7)
  double? tdee;

  AiReportModel({
    required this.id,
    required this.type,
    required this.date,
    required this.content,
    required this.createdAt,
    this.caloriesConsumed,
    this.weightKg,
    this.tdee,
  });

  AiReportType get reportType =>
      type == 'weekly' ? AiReportType.weekly : AiReportType.daily;
}
