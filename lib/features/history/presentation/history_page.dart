import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/data/dashboard_repository.dart';
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
    required this.onDateSelected,
  });

  final DateTime anchorDate;
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
      onPressed: () => _showPicker(context),
      child: Icon(
        CupertinoIcons.calendar,
        size: 22,
        color: iconColor,
      ),
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    DateTime tempDate = anchorDate;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        return Container(
          height: 330,
          color: CupertinoDynamicColor.resolve(
            AppColor.systemBackground,
            context,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.l,
                    vertical: AppSpace.s,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).pop();
                          onDateSelected(tempDate);
                        },
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 0.5,
                  color: CupertinoDynamicColor.resolve(
                    AppColor.separator,
                    context,
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: anchorDate,
                    onDateTimeChanged: (date) {
                      tempDate = date;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
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
