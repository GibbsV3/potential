import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/data/dashboard_repository.dart';
import '../../../core/domain/progress_calculator.dart';
import '../../../core/domain/routine.dart';
import '../../../design_system/design_system.dart';
import 'bloc/history_bloc.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HistoryBloc(
        context.read<DashboardRepository>(),
      )..add(const HistoryLoaded()),
      child: const _HistoryView(),
    );
  }
}

class _CalendarSheet extends StatefulWidget {
  const _CalendarSheet({
    required this.anchorDate,
    required this.routines,
    required this.completions,
    required this.onDateSelected,
  });

  final DateTime anchorDate;
  final List<Routine> routines;
  final Map<String, Map<String, double>> completions;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<_CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends State<_CalendarSheet> {
  late final DateTime _anchorMonth =
      DateTime(widget.anchorDate.year, widget.anchorDate.month);
  late final List<DateTime> _months = _buildMonths();
  final GlobalKey _anchorMonthKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final anchorContext = _anchorMonthKey.currentContext;
      if (anchorContext != null) {
        Scrollable.ensureVisible(
          anchorContext,
          duration: AppMotion.quick,
          curve: Curves.easeOut,
          alignment: 0.02,
        );
      }
    });
  }

  List<DateTime> _buildMonths() {
    // Show the anchor month with one month before and two months after
    // to mirror the inspirational scroll while keeping content manageable.
    return List<DateTime>.generate(
      4,
      (index) => _shiftMonth(_anchorMonth, index - 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final background = CupertinoDynamicColor.resolve(
      AppColor.systemBackground,
      context,
    );
    final separator = CupertinoDynamicColor.resolve(
      AppColor.separator,
      context,
    );

    return CupertinoPopupSurface(
      isSurfacePainted: true,
      child: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.92,
          color: background,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.l,
                  AppSpace.l,
                  AppSpace.l,
                  AppSpace.s,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        _fullMonthLabel(_anchorMonth),
                        style: AppTextStyle.title1(context).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(context).pop(),
                        child: Icon(
                          CupertinoIcons.xmark_circle,
                          color: CupertinoDynamicColor.resolve(
                            AppColor.secondaryLabel,
                            context,
                          ),
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 0.5, color: separator),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.l,
                    AppSpace.l,
                    AppSpace.l,
                    AppSpace.xxxl,
                  ),
                  itemCount: _months.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpace.xl),
                  itemBuilder: (context, index) {
                    final month = _months[index];
                    final isAnchor = month.year == _anchorMonth.year &&
                        month.month == _anchorMonth.month;
                    return _MonthSection(
                      key: isAnchor ? _anchorMonthKey : null,
                      month: month,
                      selectedDate: widget.anchorDate,
                      routines: widget.routines,
                      completions: widget.completions,
                      onDateSelected: (date) {
                        widget.onDateSelected(date);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthSection extends StatelessWidget {
  const _MonthSection({
    super.key,
    required this.month,
    required this.selectedDate,
    required this.routines,
    required this.completions,
    required this.onDateSelected,
  });

  final DateTime month;
  final DateTime selectedDate;
  final List<Routine> routines;
  final Map<String, Map<String, double>> completions;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final days = _buildCalendarDays(month);
    final divider = CupertinoDynamicColor.resolve(
      AppColor.separator,
      context,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
          child: Text(
            _monthLabel(month),
            style: AppTextStyle.title1(context).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppSpace.s),
        const _WeekdayHeader(),
        Container(
          height: 0.5,
          margin: const EdgeInsets.only(top: AppSpace.s),
          color: divider,
        ),
        const SizedBox(height: AppSpace.m),
        _CalendarGrid(
          month: month,
          days: days,
          selectedDate: selectedDate,
          routines: routines,
          completions: completions,
          onDateSelected: onDateSelected,
        ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoDynamicColor.resolve(
      AppColor.secondaryLabel,
      context,
    );
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyle.caption(context).copyWith(
                color: secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.days,
    required this.selectedDate,
    required this.routines,
    required this.completions,
    required this.onDateSelected,
  });

  final DateTime month;
  final List<DateTime> days;
  final DateTime selectedDate;
  final List<Routine> routines;
  final Map<String, Map<String, double>> completions;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final rowCount = (days.length / 7).ceil();
    final normalizedSelected = normalizeDate(selectedDate);
    return Column(
      children: [
        for (var row = 0; row < rowCount; row++) ...[
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: _CalendarDayCell(
                    date: days[(row * 7) + col],
                    isInMonth: days[(row * 7) + col].month == month.month &&
                        days[(row * 7) + col].year == month.year,
                    isSelected: normalizeDate(days[(row * 7) + col]) ==
                        normalizedSelected,
                    progress: _progressForDate(
                      date: days[(row * 7) + col],
                      routines: routines,
                      completions: completions,
                    ),
                    onSelected: onDateSelected,
                  ),
                ),
            ],
          ),
          if (row != rowCount - 1) const SizedBox(height: AppSpace.m),
        ],
      ],
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.isInMonth,
    required this.isSelected,
    required this.progress,
    required this.onSelected,
  });

  final DateTime date;
  final bool isInMonth;
  final bool isSelected;
  final double progress;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final accent = CupertinoDynamicColor.resolve(
      AppColor.accent,
      context,
    );
    final labelColor = CupertinoDynamicColor.resolve(
      isSelected
          ? AppColor.label
          : isInMonth
              ? AppColor.label
              : AppColor.secondaryLabel,
      context,
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onSelected(normalizeDate(date));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DayRing(
              progress: progress,
              isSelected: isSelected,
              accent: accent,
              faded: !isInMonth,
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              '${date.day}',
              style: AppTextStyle.body(context).copyWith(
                color: labelColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayRing extends StatelessWidget {
  const _DayRing({
    required this.progress,
    required this.isSelected,
    required this.accent,
    required this.faded,
  });

  final double progress;
  final bool isSelected;
  final Color accent;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final track = CupertinoDynamicColor.resolve(
      AppColor.separator,
      context,
    );
    final size = isSelected ? 42.0 : 38.0;
    final background = isSelected
        ? accent.withOpacity(0.18)
        : CupertinoColors.transparent;
    final adjustedProgress = progress.clamp(0.0, 1.0);
    return AnimatedContainer(
      duration: AppMotion.quick,
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(AppSpace.xs),
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      child: CustomPaint(
        size: Size.square(size),
        painter: _DayRingPainter(
          progress: adjustedProgress,
          progressColor:
              faded ? accent.withOpacity(0.4) : accent,
          trackColor: faded ? track.withOpacity(0.4) : track,
          isSelected: isSelected,
        ),
      ),
    );
  }
}

class _DayRingPainter extends CustomPainter {
  _DayRingPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    required this.isSelected,
  });

  final double progress;
  final Color progressColor;
  final Color trackColor;
  final bool isSelected;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = isSelected ? 3.0 : 2.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) {
      return;
    }

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final sweepAngle = (math.pi * 2) * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DayRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.isSelected != isSelected;
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        return CupertinoPageScaffold(
          child: CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: const Text('History'),
                trailing: _CalendarButton(
                  anchorDate: state.anchorDate,
                  routines: state.routines,
                  completions: state.completions,
                  onDateSelected: (date) {
                    context
                        .read<HistoryBloc>()
                        .add(HistoryAnchorChanged(date));
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.l,
                    AppSpace.s,
                    AppSpace.l,
                    AppSpace.l,
                  ),
                  child: _HistoryContent(state: state),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CalendarButton extends StatelessWidget {
  const _CalendarButton({
    required this.anchorDate,
    required this.routines,
    required this.completions,
    required this.onDateSelected,
  });

  final DateTime anchorDate;
  final List<Routine> routines;
  final Map<String, Map<String, double>> completions;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final iconColor = CupertinoDynamicColor.resolve(
      AppColor.label,
      context,
    );
    return CupertinoButton(
      padding: EdgeInsets.zero,
      alignment: Alignment.centerRight,
      onPressed: () => _showCalendar(context),
      child: Icon(
        CupertinoIcons.calendar,
        size: 22,
        color: iconColor,
      ),
    );
  }

  Future<void> _showCalendar(BuildContext context) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        return _CalendarSheet(
          anchorDate: anchorDate,
          routines: routines,
          completions: completions,
          onDateSelected: onDateSelected,
        );
      },
    );
  }
}

DateTime _shiftMonth(DateTime month, int offset) {
  return DateTime(month.year, month.month + offset, 1);
}

int _daysInMonth(DateTime month) {
  final startOfNextMonth = DateTime(month.year, month.month + 1, 1);
  return startOfNextMonth.subtract(const Duration(days: 1)).day;
}

List<DateTime> _buildCalendarDays(DateTime month) {
  final monthStart = DateTime(month.year, month.month, 1);
  final leadingEmpty = monthStart.weekday % 7;
  final daysInMonth = _daysInMonth(monthStart);
  final previousMonth = _shiftMonth(monthStart, -1);
  final previousMonthDays = _daysInMonth(previousMonth);
  final totalCells = leadingEmpty + daysInMonth;
  final trailingEmpty = (7 - (totalCells % 7)) % 7;
  final nextMonth = _shiftMonth(monthStart, 1);

  final dates = <DateTime>[];
  for (var i = 0; i < leadingEmpty; i++) {
    final day = previousMonthDays - (leadingEmpty - 1 - i);
    dates.add(DateTime(previousMonth.year, previousMonth.month, day));
  }
  for (var day = 1; day <= daysInMonth; day++) {
    dates.add(DateTime(monthStart.year, monthStart.month, day));
  }
  for (var i = 0; i < trailingEmpty; i++) {
    dates.add(DateTime(nextMonth.year, nextMonth.month, i + 1));
  }
  return dates;
}

String _fullMonthLabel(DateTime month) {
  const names = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final safeIndex = (month.month - 1).clamp(0, names.length - 1);
  return '${names[safeIndex]} ${month.year}';
}

String _monthLabel(DateTime month) {
  const short = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final safeIndex = (month.month - 1).clamp(0, short.length - 1);
  return '${short[safeIndex]} ${month.year}';
}

double _progressForDate({
  required DateTime date,
  required List<Routine> routines,
  required Map<String, Map<String, double>> completions,
}) {
  if (routines.isEmpty) {
    return 0;
  }
  return weightedProgressForDate(
    date: date,
    routines: routines,
    completions: completions,
  );
}

class _HistoryContent extends StatelessWidget {
  const _HistoryContent({required this.state});

  final HistoryState state;

  @override
  Widget build(BuildContext context) {
    if (state.status == HistoryStatus.failure) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.xl),
        child: Center(
          child: Text(
            state.errorMessage ?? 'Unable to load history.',
            style: AppTextStyle.body(context).copyWith(
              color: CupertinoDynamicColor.resolve(
                AppColor.secondaryLabel,
                context,
              ),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress over time',
          style: AppTextStyle.title1(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpace.m),
        _HistoryRangeSelector(
          range: state.range,
          onChanged: (range) {
            if (range != null) {
              HapticFeedback.selectionClick();
              context.read<HistoryBloc>().add(
                    HistoryRangeChanged(range),
                  );
            }
          },
        ),
        const SizedBox(height: AppSpace.l),
        _HistoryChartCard(
          state: state,
        ),
      ],
    );
  }
}

class _HistoryRangeSelector extends StatelessWidget {
  const _HistoryRangeSelector({
    required this.range,
    required this.onChanged,
  });

  final HistoryRange range;
  final ValueChanged<HistoryRange?> onChanged;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoDynamicColor.resolve(
      AppColor.secondaryLabel,
      context,
    );
    final thumbColor = CupertinoDynamicColor.resolve(
      AppColor.systemBackground,
      context,
    );
    final backgroundColor = CupertinoDynamicColor.resolve(
      AppColor.secondarySystemGroupedBackground,
      context,
    );

    return AppSlidingSegmentedControl<HistoryRange>(
      segments: [
        AppSlidingSegment<HistoryRange>(
          value: HistoryRange.daily,
          builder: (context, selected) => Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpace.s,
              horizontal: AppSpace.xl,
            ),
            child: Text(
              'Daily',
              style: AppTextStyle.body(context).copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? null : secondary,
              ),
            ),
          ),
        ),
        AppSlidingSegment<HistoryRange>(
          value: HistoryRange.weekly,
          builder: (context, selected) => Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpace.s,
              horizontal: AppSpace.xl,
            ),
            child: Text(
              'Weekly',
              style: AppTextStyle.body(context).copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? null : secondary,
              ),
            ),
          ),
        ),
      ],
      value: range,
      onChanged: (value) => onChanged(value),
      backgroundColor: backgroundColor,
      thumbColor: thumbColor,
      padding: const EdgeInsets.all(AppSpace.xs),
      thumbInset: 0,
    );
  }
}

class _HistoryChartCard extends StatelessWidget {
  const _HistoryChartCard({required this.state});

  final HistoryState state;

  @override
  Widget build(BuildContext context) {
    final background = CupertinoDynamicColor.resolve(
      AppColor.secondarySystemGroupedBackground,
      context,
    );
    final border = CupertinoDynamicColor.resolve(
      AppColor.separator,
      context,
    );
    final secondary = CupertinoDynamicColor.resolve(
      AppColor.secondaryLabel,
      context,
    );
    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: border,
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.all(AppSpace.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedSwitcher(
                duration: AppMotion.standard,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: Text(
                  _rangeLabel(state.range),
                  key: ValueKey(state.range),
                  style: AppTextStyle.body(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (state.status == HistoryStatus.loading)
                const CupertinoActivityIndicator()
              else
                AnimatedSwitcher(
                  duration: AppMotion.standard,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: Text(
                    _anchorLabel(state.anchorDate),
                    key: ValueKey(state.anchorDate.toIso8601String()),
                    style: AppTextStyle.footnote(context).copyWith(
                      color: secondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.m),
          _HistoryChart(
            points: state.points,
          ),
          const SizedBox(height: AppSpace.s),
          AnimatedSwitcher(
            duration: AppMotion.standard,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: _XAxisLabels(
              key: ValueKey('${state.range}-${state.anchorDate}'),
              points: state.points,
              range: state.range,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryChart extends StatefulWidget {
  const _HistoryChart({
    super.key,
    required this.points,
  });

  final List<HistoryPoint> points;

  @override
  State<_HistoryChart> createState() => _HistoryChartState();
}

class _HistoryChartState extends State<_HistoryChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<HistoryPoint> _previousPoints;
  late List<HistoryPoint> _targetPoints;

  @override
  void initState() {
    super.initState();
    _previousPoints = widget.points;
    _targetPoints = widget.points;
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.quick,
    )..value = 1;
  }

  @override
  void didUpdateWidget(covariant _HistoryChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.points, _targetPoints)) {
      _previousPoints = _lerpPoints(_controller.value);
      _targetPoints = widget.points;
      _controller
        ..duration = AppMotion.quick
        ..forward(from: 0);
    }
  }

  List<HistoryPoint> _lerpPoints(double t) {
    final maxLength = _targetPoints.length > _previousPoints.length
        ? _targetPoints.length
        : _previousPoints.length;
    return List<HistoryPoint>.generate(maxLength, (index) {
      final targetPoint = index < _targetPoints.length
          ? _targetPoints[index]
          : _previousPoints[index];
      final startProgress = index < _previousPoints.length
          ? _previousPoints[index].progress
          : 0.0;
      final endProgress = index < _targetPoints.length
          ? _targetPoints[index].progress
          : startProgress;
      final interpolatedProgress =
          lerpDouble(startProgress, endProgress, t) ?? endProgress;
      return HistoryPoint(
        date: targetPoint.date,
        progress: interpolatedProgress,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chartColor = CupertinoDynamicColor.resolve(
      AppColor.accent,
      context,
    );
    final gridColor = CupertinoDynamicColor.resolve(
      AppColor.separator,
      context,
    );
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final animatedPoints = _lerpPoints(_controller.value);
        return AspectRatio(
          aspectRatio: 1.4,
          child: CustomPaint(
            painter: _HistoryChartPainter(
              points: animatedPoints,
              accentColor: chartColor,
              gridColor: gridColor,
            ),
          ),
        );
      },
    );
  }
}

class _HistoryChartPainter extends CustomPainter {
  _HistoryChartPainter({
    required this.points,
    required this.accentColor,
    required this.gridColor,
  });

  final List<HistoryPoint> points;
  final Color accentColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }
    final chartRect = Rect.fromLTWH(
      AppSpace.l,
      AppSpace.s,
      size.width - (AppSpace.l * 2),
      size.height - (AppSpace.s * 2),
    );

    final horizontalStep =
        points.length <= 1 ? 0.0 : chartRect.width / (points.length - 1);
    final gridPaint = Paint()
      ..color = gridColor.withOpacity(0.5)
      ..strokeWidth = 0.8;

    for (final fraction in [0.0, 0.5, 1.0]) {
      final dy = chartRect.bottom - (chartRect.height * fraction);
      canvas.drawLine(
        Offset(chartRect.left, dy),
        Offset(chartRect.right, dy),
        gridPaint,
      );
    }

    final path = Path();
    final fillPath = Path();
    for (var i = 0; i < points.length; i++) {
      final progress = points[i].progress.clamp(0, 1);
      final dx = chartRect.left + (horizontalStep * i);
      final dy = chartRect.bottom - (chartRect.height * progress);
      final point = Offset(dx, dy);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
        fillPath.moveTo(point.dx, chartRect.bottom);
        fillPath.lineTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
        fillPath.lineTo(point.dx, point.dy);
      }
      if (i == points.length - 1) {
        fillPath.lineTo(point.dx, chartRect.bottom);
        fillPath.close();
      }
    }

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withOpacity(0.14),
          accentColor.withOpacity(0.1),
          accentColor.withOpacity(0.06),
          accentColor.withOpacity(0.03),
        ],
        stops: const [0.0, 0.35, 0.7, 1.0],
      ).createShader(chartRect)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    for (var i = 0; i < points.length; i++) {
      final progress = points[i].progress.clamp(0, 1);
      final dx = chartRect.left + (horizontalStep * i);
      final dy = chartRect.bottom - (chartRect.height * progress);
      canvas.drawCircle(Offset(dx, dy), 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HistoryChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.gridColor != gridColor;
  }
}

class _XAxisLabels extends StatelessWidget {
  const _XAxisLabels({
    super.key,
    required this.points,
    required this.range,
  });

  final List<HistoryPoint> points;
  final HistoryRange range;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }
    final color = CupertinoDynamicColor.resolve(
      AppColor.secondaryLabel,
      context,
    );
    final labels = points
        .map((point) => _formatXAxisLabel(point.date, range))
        .toList();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < labels.length; index++)
          Expanded(
            child: Text(
              labels[index],
              textAlign: TextAlign.center,
              style: AppTextStyle.caption(context).copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

String _rangeLabel(HistoryRange range) {
  switch (range) {
    case HistoryRange.daily:
      return 'Last 7 days';
    case HistoryRange.weekly:
      return 'Last 7 weeks';
  }
}

String _anchorLabel(DateTime anchorDate) {
  final monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${monthNames[anchorDate.month - 1]} ${anchorDate.day}';
}

String _formatXAxisLabel(DateTime date, HistoryRange range) {
  const weekdayInitials = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];
  const monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  switch (range) {
    case HistoryRange.daily:
      return weekdayInitials[date.weekday % 7];
    case HistoryRange.weekly:
      final month = monthNames[date.month - 1];
      return '$month ${date.day}';
  }
}
