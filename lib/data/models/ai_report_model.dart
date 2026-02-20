import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

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

  AiReportModel({
    required this.id,
    required this.type,
    required this.date,
    required this.content,
    required this.createdAt,
  });

  AiReportType get reportType =>
      type == 'weekly' ? AiReportType.weekly : AiReportType.daily;
}
