import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/data/dashboard_repository.dart';
import '../../../core/domain/task.dart';
import '../../../design_system/design_system.dart';
import 'bloc/dashboard_bloc.dart';
import 'dashboard_date_utils.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardBloc(
        context.read<DashboardRepository>(),
      )..add(const DashboardLoaded()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        return CupertinoPageScaffold(
          child: CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: _HeaderDatePicker(
                  selectedDate: state.selectedDate,
                  onDatePicked: (date) {
                    context
                        .read<DashboardBloc>()
                        .add(DashboardDateSelected(date));
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DailyProgressSummary(
                        progress: state.dailyProgress,
                        selectedDate: state.selectedDate,
                      ),
                      const SizedBox(height: AppSpace.xl),
                      _WeekdaySelector(
                        selectedDate: state.selectedDate,
                        progressForDate: state.progressForDate,
                        onSelected: (date) {
                          context
                              .read<DashboardBloc>()
                              .add(DashboardDateSelected(date));
                        },
                      ),
                      const SizedBox(height: AppSpace.xl),
                    ],
                  ),
                ),
              ),
              if (state.status == DashboardStatus.loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: AppSpace.xl),
                    child: Center(child: CupertinoActivityIndicator()),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final progress = state.routineProgress[index];
                      return _RoutineSection(
                        title: progress.routine.title,
                        progress: progress.completion,
                        tasks: progress.routine.tasks,
                        completions: state.selectedDayCompletions,
                        selectedDate: state.selectedDate,
                      );
                    },
                    childCount: state.routineProgress.length,
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpace.xxxl),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderDatePicker extends StatelessWidget {
  const _HeaderDatePicker({
    required this.selectedDate,
    required this.onDatePicked,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDatePicked;

  @override
  Widget build(BuildContext context) {
    final color = CupertinoDynamicColor.resolve(AppColor.label, context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showDatePicker(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatDayLabel(selectedDate),
            style: AppTextStyle.largeTitle(context).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppSpace.s),
          Icon(
            CupertinoIcons.chevron_down,
            size: 18,
            color: color,
          ),
        ],
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    DateTime tempDate = selectedDate;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        return Container(
          height: 320,
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
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).pop();
                          onDatePicked(_normalize(tempDate));
                        },
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: selectedDate,
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

class _DailyProgressSummary extends StatelessWidget {
  const _DailyProgressSummary({
    required this.progress,
    required this.selectedDate,
  });

  final double progress;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatDayLabel(selectedDate),
          style: AppTextStyle.title1(context),
        ),
        const SizedBox(height: AppSpace.s),
        _ProgressBar(progress: progress),
        const SizedBox(height: AppSpace.s),
        Text(
          '$percent% of weighted routines completed',
          style: AppTextStyle.footnote(context).copyWith(
            color: CupertinoDynamicColor.resolve(
              AppColor.secondaryLabel,
              context,
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekdaySelector extends StatelessWidget {
  const _WeekdaySelector({
    required this.selectedDate,
    required this.progressForDate,
    required this.onSelected,
  });

  final DateTime selectedDate;
  final double Function(DateTime date) progressForDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final dates = weekDates(selectedDate);
    final todayKey = dateKey(DateTime.now());
    final selectedKey = dateKey(selectedDate);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final date in dates)
            Expanded(
              child: _DayCell(
                date: date,
                isSelected: dateKey(date) == selectedKey,
                isToday: dateKey(date) == todayKey,
                progress: progressForDate(date),
                onSelected: onSelected,
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.progress,
    required this.onSelected,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final double progress;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final labelColor = CupertinoDynamicColor.resolve(
      isSelected ? AppColor.label : AppColor.secondaryLabel,
      context,
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onSelected(date);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _weekdayInitial(date.weekday),
            textAlign: TextAlign.center,
            style: AppTextStyle.body(context).copyWith(
              color: labelColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          if (isToday)
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: CupertinoDynamicColor.resolve(
                  AppColor.secondaryLabel,
                  context,
                ),
                shape: BoxShape.circle,
              ),
            )
          else
            const SizedBox(height: 4),
          const SizedBox(height: AppSpace.s),
          _ProgressRing(
            progress: progress,
            isSelected: isSelected,
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.progress,
    required this.isSelected,
  });

  final double progress;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final resolvedProgress = progress.clamp(0, 1) as double;
    final trackColor = CupertinoDynamicColor.resolve(
      AppColor.separator,
      context,
    );
    final accentColor = CupertinoDynamicColor.resolve(
      AppColor.accent,
      context,
    );
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: resolvedProgress),
      duration: AppMotion.standard,
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return CustomPaint(
          size: const Size.square(40),
          painter: _ProgressRingPainter(
            progress: value,
            trackColor: trackColor,
            progressColor: accentColor,
            isSelected: isSelected,
          ),
        );
      },
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.isSelected,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
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

    final startAngle = -math.pi / 2;
    final sweepAngle = (math.pi * 2) * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.isSelected != isSelected;
  }
}

class _RoutineSection extends StatelessWidget {
  const _RoutineSection({
    required this.title,
    required this.progress,
    required this.tasks,
    required this.completions,
    required this.selectedDate,
  });

  final String title;
  final double progress;
  final List<Task> tasks;
  final Map<String, double> completions;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    // Use inset grouped sections to align with iOS list hierarchy.
    final dividerColor = CupertinoDynamicColor.resolve(
      AppColor.separator,
      context,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.l,
        AppSpace.s,
        AppSpace.l,
        AppSpace.l,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyle.title1(context),
          ),
          const SizedBox(height: AppSpace.s),
          Container(
            decoration: BoxDecoration(
              color: CupertinoDynamicColor.resolve(
                AppColor.secondarySystemGroupedBackground,
                context,
              ),
              borderRadius: AppRadius.card,
            ),
            child: Column(
              children: [
                for (var i = 0; i < tasks.length; i++) ...[
                  _TaskRow(
                    task: tasks[i],
                    progress: completions[tasks[i].id] ?? 0,
                    selectedDate: selectedDate,
                    isFirst: i == 0,
                    isLast: i == tasks.length - 1,
                  ),
                  if (i != tasks.length - 1)
                    Container(
                      height: 0.5,
                      margin: const EdgeInsets.only(left: AppSpace.xl),
                      color: dividerColor,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.progress,
    required this.selectedDate,
    required this.isFirst,
    required this.isLast,
  });

  final Task task;
  final double progress;
  final DateTime selectedDate;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return _TaskRowGesture(
      task: task,
      progress: progress,
      selectedDate: selectedDate,
      radius: _rowRadius(),
    );
  }

  BorderRadius _rowRadius() {
    final radius = AppRadius.card.topLeft;
    return BorderRadius.only(
      topLeft: isFirst ? radius : Radius.zero,
      topRight: isFirst ? radius : Radius.zero,
      bottomLeft: isLast ? radius : Radius.zero,
      bottomRight: isLast ? radius : Radius.zero,
    );
  }
}

class _TaskRowGesture extends StatefulWidget {
  const _TaskRowGesture({
    required this.task,
    required this.progress,
    required this.selectedDate,
    required this.radius,
  });

  final Task task;
  final double progress;
  final DateTime selectedDate;
  final BorderRadius radius;

  @override
  State<_TaskRowGesture> createState() => _TaskRowGestureState();
}

class _TaskRowGestureState extends State<_TaskRowGesture> {
  double _localProgress = 0;
  double _displayProgress = 0;
  bool _isDragging = false;
  double _startProgress = 0;
  double _dragWidth = 1;
  bool _hitZero = false;
  bool _hitHundred = false;

  @override
  void initState() {
    super.initState();
    _localProgress = widget.progress.clamp(0, 1);
    _displayProgress = _localProgress;
  }

  @override
  void didUpdateWidget(covariant _TaskRowGesture oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging && widget.progress != oldWidget.progress) {
      setState(() {
        _displayProgress = _localProgress;
        _localProgress = widget.progress.clamp(0, 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _localProgress > 0.7
        ? CupertinoColors.white
        : CupertinoDynamicColor.resolve(AppColor.label, context);
    final secondaryText = _localProgress > 0.7
        ? CupertinoColors.white.withOpacity(0.85)
        : CupertinoDynamicColor.resolve(AppColor.secondaryLabel, context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      onLongPressStart: _handleLongPressStart,
      onLongPressMoveUpdate: _handleLongPressMove,
      onLongPressEnd: (_) => _endDrag(),
      onLongPressCancel: _endDrag,
      child: SizedBox(
        height: 64,
        child: Stack(
          alignment: Alignment.centerLeft,
          clipBehavior: Clip.hardEdge,
          children: [
            ClipRRect(
              borderRadius: widget.radius,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  duration: AppMotion.standard,
                  curve: Curves.easeOut,
                  tween: Tween<double>(
                    begin: _displayProgress,
                    end: _localProgress.clamp(0, 1),
                  ),
                  onEnd: () => _displayProgress = _localProgress,
                  builder: (context, value, child) {
                    final clamped = value.clamp(0.0, 1.0);
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: clamped,
                      child: Container(
                        color: CupertinoDynamicColor.resolve(
                          AppColor.accent,
                          context,
                        ).withOpacity(0.12 + (clamped * 0.28)),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.l,
                vertical: AppSpace.m,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.task.title,
                      style: AppTextStyle.body(context).copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.s),
                  Text(
                    '${(_localProgress * 100).round()}%',
                    style: AppTextStyle.footnote(context).copyWith(
                      color: secondaryText,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    context.read<DashboardBloc>().add(
          DashboardTaskToggled(
            date: widget.selectedDate,
            taskId: widget.task.id,
          ),
        );
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    final renderBox = context.findRenderObject() as RenderBox?;
    _dragWidth = renderBox?.size.width ?? 1;
    _startProgress = _localProgress;
    _isDragging = true;
    _hitZero = _startProgress <= 0.0;
    _hitHundred = _startProgress >= 1.0;
    HapticFeedback.selectionClick();
  }

  void _handleLongPressMove(LongPressMoveUpdateDetails details) {
    if (!_isDragging) return;
    final delta = details.offsetFromOrigin.dx;
    final raw = (_startProgress + (delta / _dragWidth)).clamp(0.0, 1.0);
    final stepped = (raw * 100).round() / 100;
    if (stepped == _localProgress) return;

    setState(() {
      _displayProgress = _localProgress;
      _localProgress = stepped;
    });

    if (!_hitZero && stepped <= 0.0) {
      _hitZero = true;
      HapticFeedback.selectionClick();
    } else if (!_hitHundred && stepped >= 1.0) {
      _hitHundred = true;
      HapticFeedback.selectionClick();
    }

    context.read<DashboardBloc>().add(
          DashboardTaskProgressChanged(
            date: widget.selectedDate,
            taskId: widget.task.id,
            progress: stepped,
          ),
        );
  }

  void _endDrag() {
    _isDragging = false;
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.pill,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth * progress.clamp(0, 1);
          return Stack(
            children: [
              Container(
                height: 8,
                color: CupertinoDynamicColor.resolve(
                  AppColor.separator,
                  context,
                ),
              ),
              AnimatedContainer(
                duration: AppMotion.relaxed,
                curve: Curves.easeOut,
                height: 8,
                width: width,
                color: AppColor.accent,
              ),
            ],
          );
        },
      ),
    );
  }
}

String _formatDayLabel(DateTime date) {
  final normalized = _normalize(date);
  final today = _normalize(DateTime.now());
  if (normalized == today) {
    return 'Today';
  }
  if (normalized ==
      today.add(const Duration(
        days: 1,
      ))) {
    return 'Tomorrow';
  }
  if (normalized ==
      today.subtract(const Duration(
        days: 1,
      ))) {
    return 'Yesterday';
  }
  final weekdayName = _weekdayName(normalized.weekday);
  final monthName = _monthLabel(normalized.month);
  return '$weekdayName, $monthName ${normalized.day}';
}

String _weekdayInitial(int weekday) {
  const initials = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  return initials[weekday % 7];
}

String _weekdayName(int weekday) {
  const names = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];
  return names[weekday % 7];
}

String _monthLabel(int month) {
  const months = [
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
  return months[(month - 1).clamp(0, months.length - 1)];
}

DateTime _normalize(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}
