import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/ai_report_model.dart';
import '../../../data/models/tag_model.dart';
import '../../../data/repositories/ai_report_repository.dart';
import '../../../data/repositories/tag_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/services/report_service.dart';

// ─── Data models ──────────────────────────────────────────────────────────────

class _DayStat {
  final String label;
  final int total;
  final int done;
  const _DayStat({required this.label, required this.total, required this.done});
  double get ratio => total == 0 ? 0 : done / total;
}

class _WeekStats {
  final List<_DayStat> days;
  final int totalTasks;
  final int completedTasks;
  final int weekTasks;
  final int weekDone;
  const _WeekStats({
    required this.days,
    required this.totalTasks,
    required this.completedTasks,
    required this.weekTasks,
    required this.weekDone,
  });
  double get overallRatio => totalTasks == 0 ? 0 : completedTasks / totalTasks;
  double get weekRatio => weekTasks == 0 ? 0 : weekDone / weekTasks;
}

class _TagStat {
  final String name;
  final String emoji;
  final int count;
  final int done;
  final Color color;
  const _TagStat({required this.name, required this.emoji, required this.count, required this.done, required this.color});
  double get ratio => count == 0 ? 0 : done / count;
}

// ─── Палитра для тегов ────────────────────────────────────────────────────────
const _tagPalette = [
  Color(0xFF4CAF50), Color(0xFF2196F3), Color(0xFFFFC107),
  Color(0xFFE91E63), Color(0xFF9C27B0), Color(0xFF00BCD4),
  Color(0xFFFF5722), Color(0xFF8BC34A),
];

// ─── Daily Tab ────────────────────────────────────────────────────────────────

class _DailyTab extends StatelessWidget {
  final AiReportRepository repo;
  final AnimationController headerAnim;
  final bool generating;
  final VoidCallback onGenerate;
  final _WeekStats weekStats;

  const _DailyTab({
    required this.repo,
    required this.headerAnim,
    required this.generating,
    required this.onGenerate,
    required this.weekStats,
  });

  @override
  Widget build(BuildContext context) {
    final reports = repo.getDaily();
    return CustomScrollView(
      slivers: [
        // Hero stats header
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: headerAnim, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero)
                  .animate(CurvedAnimation(parent: headerAnim, curve: Curves.easeOutCubic)),
              child: _HeroHeader(weekStats: weekStats, onGenerate: onGenerate, generating: generating),
            ),
          ),
        ),
        // Reports list
        if (reports.isEmpty)
          const SliverFillRemaining(child: _EmptyReports())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _AnimatedReportCard(report: reports[i], index: i),
                childCount: reports.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Hero Header ──────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final _WeekStats weekStats;
  final VoidCallback onGenerate;
  final bool generating;
  const _HeroHeader({required this.weekStats, required this.onGenerate, required this.generating});

  @override
  Widget build(BuildContext context) {
    final pct = (weekStats.weekRatio * 100).round();
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Эта неделя',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Text('$pct%',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          _AnimatedBar(ratio: weekStats.weekRatio, color: AppColors.priorityColors[4]),
          const SizedBox(height: 6),
          Text('${weekStats.weekDone} из ${weekStats.weekTasks} задач выполнено',
              style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(label: 'Всего задач', value: '${weekStats.totalTasks}', icon: '📋'),
              const SizedBox(width: 8),
              _StatChip(label: 'Выполнено', value: '${weekStats.completedTasks}', icon: '✅'),
              const SizedBox(width: 8),
              _StatChip(
                  label: 'Процент',
                  value: '${(weekStats.overallRatio * 100).round()}%',
                  icon: '🎯'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceVariant,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: generating ? null : onGenerate,
              icon: generating
                  ? const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary))
                  : const Text('✨', style: TextStyle(fontSize: 14)),
              label: Text(generating ? 'Генерирую...' : 'Сгенерировать отчёт за сегодня',
                  style: const TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  const _StatChip({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 9), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Stats Tab ────────────────────────────────────────────────────────────────

class _StatsTab extends StatelessWidget {
  final AnimationController statsAnim;
  final _WeekStats weekStats;
  final List<_TagStat> tagStats;
  final bool generating;
  final VoidCallback onGenerate;
  final List<AiReportModel> weeklyReports;

  const _StatsTab({
    required this.statsAnim,
    required this.weekStats,
    required this.tagStats,
    required this.generating,
    required this.onGenerate,
    required this.weeklyReports,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: statsAnim,
      builder: (ctx, _) {
        final anim = CurvedAnimation(parent: statsAnim, curve: Curves.easeOutCubic);
        return CustomScrollView(
          slivers: [
            // Bar chart — tasks per day this week
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: anim,
                child: _BarChartCard(days: weekStats.days, anim: statsAnim),
              ),
            ),
            // Tag donut + list
            if (tagStats.isNotEmpty)
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: anim,
                  child: _TagChartCard(tagStats: tagStats, anim: statsAnim),
                ),
              ),
            // Weekly reports + generate button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Недельные отчёты',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                      onPressed: generating ? null : onGenerate,
                      icon: generating
                          ? const SizedBox(width: 12, height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary))
                          : const Icon(Icons.auto_awesome, size: 14),
                      label: Text(generating ? '...' : 'Создать', style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
            if (weeklyReports.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: _EmptyReports(),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _AnimatedReportCard(report: weeklyReports[i], index: i),
                    childCount: weeklyReports.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─── Bar Chart ────────────────────────────────────────────────────────────────

class _BarChartCard extends StatelessWidget {
  final List<_DayStat> days;
  final AnimationController anim;
  const _BarChartCard({required this.days, required this.anim});

  @override
  Widget build(BuildContext context) {
    final maxTotal = days.fold<int>(0, (m, d) => d.total > m ? d.total : m);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Задачи по дням (эта неделя)',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Серый = всего, цвет = выполнено',
              style: TextStyle(color: AppColors.textHint, fontSize: 11)),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: AnimatedBuilder(
              animation: anim,
              builder: (ctx, _) {
                final progress = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic).value;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: days.map((d) {
                    final totalH = maxTotal == 0 ? 0.0 : (d.total / maxTotal) * 100 * progress;
                    final doneH = maxTotal == 0 ? 0.0 : (d.done / maxTotal) * 100 * progress;
                    final isToday = days.indexOf(d) == (DateTime.now().weekday - 1);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (d.total > 0)
                              Text('${d.done}', style: TextStyle(
                                color: isToday ? AppColors.textPrimary : AppColors.textHint,
                                fontSize: 9, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            SizedBox(
                              height: 100,
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  // Total bar
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      height: totalH,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        borderRadius: BorderRadius.circular(4),
                                        border: isToday ? Border.all(color: AppColors.textSecondary, width: 1) : null,
                                      ),
                                    ),
                                  ),
                                  // Done bar
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      height: doneH,
                                      decoration: BoxDecoration(
                                        color: AppColors.priorityColors[4].withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(d.label, style: TextStyle(
                              color: isToday ? AppColors.textPrimary : AppColors.textHint,
                              fontSize: 10,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            )),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tag Donut Chart ──────────────────────────────────────────────────────────

class _TagChartCard extends StatelessWidget {
  final List<_TagStat> tagStats;
  final AnimationController anim;
  const _TagChartCard({required this.tagStats, required this.anim});

  @override
  Widget build(BuildContext context) {
    final top = tagStats.take(6).toList();
    final total = top.fold<int>(0, (s, t) => s + t.count);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Распределение по тегам',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              // Donut
              AnimatedBuilder(
                animation: anim,
                builder: (ctx, _) {
                  final progress = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic).value;
                  return SizedBox(
                    width: 110,
                    height: 110,
                    child: CustomPaint(
                      painter: _DonutPainter(
                        segments: top.map((t) => _DonutSegment(
                          value: t.count.toDouble(),
                          color: t.color,
                        )).toList(),
                        progress: progress,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$total', style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                            const Text('задач', style: TextStyle(color: AppColors.textHint, fontSize: 9)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              // Legend
              Expanded(
                child: Column(
                  children: top.map((t) {
                    final pct = total == 0 ? 0 : (t.count / total * 100).round();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(color: t.color, borderRadius: BorderRadius.circular(2)),
                          ),
                          const SizedBox(width: 6),
                          Text(t.emoji, style: const TextStyle(fontSize: 11)),
                          const SizedBox(width: 4),
                          Expanded(child: Text(t.name,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              overflow: TextOverflow.ellipsis)),
                          Text('$pct%',
                              style: const TextStyle(color: AppColors.textHint, fontSize: 10)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bars per tag
          ...top.take(5).map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('${t.emoji} ${t.name}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    const Spacer(),
                    Text('${t.done}/${t.count}',
                        style: const TextStyle(color: AppColors.textHint, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 4),
                AnimatedBuilder(
                  animation: anim,
                  builder: (ctx, _) {
                    final p = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic).value;
                    return _AnimatedBar(ratio: t.ratio * p, color: t.color, height: 5);
                  },
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _DonutSegment {
  final double value;
  final Color color;
  const _DonutSegment({required this.value, required this.color});
}

class _DonutPainter extends CustomPainter {
  final List<_DonutSegment> segments;
  final double progress;
  const _DonutPainter({required this.segments, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(0, (s, e) => s + e.value);
    if (total == 0) return;
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 14..strokeCap = StrokeCap.round;
    double startAngle = -math.pi / 2;
    final gap = 0.04;
    for (final seg in segments) {
      final sweep = (seg.value / total) * 2 * math.pi * progress - gap;
      if (sweep <= 0) continue;
      paint.color = seg.color;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress;
}

// ─── Animated bar ─────────────────────────────────────────────────────────────

class _AnimatedBar extends StatelessWidget {
  final double ratio;
  final Color color;
  final double height;
  const _AnimatedBar({required this.ratio, required this.color, this.height = 6});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      return Stack(
        children: [
          Container(
            height: height,
            width: constraints.maxWidth,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(height),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            height: height,
            width: constraints.maxWidth * ratio.clamp(0.0, 1.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(height),
            ),
          ),
        ],
      );
    });
  }
}

// ─── Animated Report Card ─────────────────────────────────────────────────────

class _AnimatedReportCard extends StatefulWidget {
  final AiReportModel report;
  final int index;
  const _AnimatedReportCard({required this.report, required this.index});

  @override
  State<_AnimatedReportCard> createState() => _AnimatedReportCardState();
}

class _AnimatedReportCardState extends State<_AnimatedReportCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _ctrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _expandAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  String _formatDate(DateTime date, bool isWeekly) {
    if (isWeekly) {
      final end = date.add(const Duration(days: 6));
      final fmt = DateFormat('d MMM', 'ru');
      return '${fmt.format(date)} — ${fmt.format(end)}';
    }
    return DateFormat('d MMMM yyyy', 'ru').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isWeekly = widget.report.type == 'weekly';
    final preview = widget.report.content.length > 80
        ? '${widget.report.content.substring(0, 80)}...'
        : widget.report.content;

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _expanded ? AppColors.textSecondary.withValues(alpha: 0.6) : AppColors.border,
            width: _expanded ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(isWeekly ? '📅' : '📆',
                          style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isWeekly ? 'Итоги недели' : 'Итоги дня',
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(_formatDate(widget.report.date, isWeekly),
                            style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.keyboard_arrow_down, color: AppColors.textHint, size: 18),
                  ),
                ],
              ),
            ),
            // Preview text when collapsed
            if (!_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Text(preview,
                    style: const TextStyle(color: AppColors.textHint, fontSize: 12, height: 1.4)),
              ),
            // Expanded full text
            SizeTransition(
              sizeFactor: _expandAnim,
              child: Column(
                children: [
                  Container(height: 1, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(widget.report.content,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.65)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyReports extends StatelessWidget {
  const _EmptyReports();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text('🤖', style: TextStyle(fontSize: 48)),
          SizedBox(height: 16),
          Text('Отчётов пока нет', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          SizedBox(height: 6),
          Text('Нажмите кнопку выше\nдля генерации AI-отчёта',
              style: TextStyle(color: AppColors.textHint, fontSize: 12),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _headerAnim;
  late AnimationController _statsAnim;

  final _repo = AiReportRepository();
  final _taskRepo = TaskRepository();
  final _tagRepo = Get.find<TagRepository>();

  bool _generatingDaily = false;
  bool _generatingWeekly = false;

  // ─── Stats computed once ──────────────────────────────────────────────────
  late _WeekStats _weekStats;
  late List<_TagStat> _tagStats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _statsAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_statsAnim.isCompleted) {
        _statsAnim.forward();
      }
    });
    _computeStats();
  }

  void _computeStats() {
    final now = DateTime.now();
    final allTasks = _taskRepo.getAll();

    // Текущая неделя
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekTasks = allTasks.where((t) {
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      final ws = DateTime(weekStart.year, weekStart.month, weekStart.day);
      return !d.isBefore(ws) && d.isBefore(ws.add(const Duration(days: 7)));
    }).toList();

    // По дням
    final byDay = List.generate(7, (i) {
      final day = DateTime(weekStart.year, weekStart.month, weekStart.day + i);
      final dayTasks = weekTasks.where((t) =>
          DateTime(t.date.year, t.date.month, t.date.day) == day).toList();
      return _DayStat(
        label: _dayLabel(day.weekday),
        total: dayTasks.length,
        done: dayTasks.where((t) => t.isCompleted).length,
      );
    });

    _weekStats = _WeekStats(
      days: byDay,
      totalTasks: allTasks.length,
      completedTasks: allTasks.where((t) => t.isCompleted).length,
      weekTasks: weekTasks.length,
      weekDone: weekTasks.where((t) => t.isCompleted).length,
    );

    // По тегам (всё время)
    final tagCount = <String, int>{};
    final tagDone = <String, int>{};
    for (final t in allTasks) {
      for (final tid in t.tagIds) {
        tagCount[tid] = (tagCount[tid] ?? 0) + 1;
        if (t.isCompleted) tagDone[tid] = (tagDone[tid] ?? 0) + 1;
      }
    }
    final tags = _tagRepo.getAll();
    _tagStats = tagCount.entries.map((e) {
      final tag = tags.firstWhereOrNull((t) => t.id == e.key);
      return _TagStat(
        name: tag?.name ?? '?',
        emoji: tag?.emoji ?? '🏷',
        count: e.value,
        done: tagDone[e.key] ?? 0,
        color: _tagColor(tag),
      );
    }).toList()..sort((a, b) => b.count.compareTo(a.count));
  }

  Color _tagColor(TagModel? tag) {
    if (tag != null) return tag.color;
    final hash = (tag?.name ?? '').hashCode;
    return _tagPalette[hash.abs() % _tagPalette.length];
  }

  String _dayLabel(int weekday) {
    const labels = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
    return labels[weekday - 1];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerAnim.dispose();
    _statsAnim.dispose();
    super.dispose();
  }

  Future<void> _generateDaily() async {
    setState(() => _generatingDaily = true);
    await ReportService().generateDailyReport();
    if (mounted) setState(() { _generatingDaily = false; _computeStats(); });
  }

  Future<void> _generateWeekly() async {
    setState(() => _generatingWeekly = true);
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    await ReportService().generateWeeklyReport(weekStart: weekStart);
    if (mounted) setState(() { _generatingWeekly = false; _computeStats(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Отчёты'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.textSecondary,
          indicatorWeight: 2,
          tabs: const [
            Tab(text: 'Ежедневные'),
            Tab(text: 'Статистика'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DailyTab(
            repo: _repo,
            headerAnim: _headerAnim,
            generating: _generatingDaily,
            onGenerate: _generateDaily,
            weekStats: _weekStats,
          ),
          _StatsTab(
            statsAnim: _statsAnim,
            weekStats: _weekStats,
            tagStats: _tagStats,
            generating: _generatingWeekly,
            onGenerate: _generateWeekly,
            weeklyReports: _repo.getWeekly(),
          ),
        ],
      ),
    );
  }
}
