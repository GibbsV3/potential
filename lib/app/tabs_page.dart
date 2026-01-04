import 'dart:ui';

import 'package:flutter/cupertino.dart';

import '../design_system/design_system.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/history/presentation/history_page.dart';
import '../features/routines/presentation/routines_page.dart';

class TabsPage extends StatefulWidget {
  const TabsPage({super.key});

  @override
  State<TabsPage> createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage> {
  static const double _tabBarHeight = 48;

  final List<_TabItem> _tabs = const [
    _TabItem(label: 'History', page: HistoryPage()),
    _TabItem(label: 'Dashboard', page: DashboardPage()),
    _TabItem(label: 'Routines', page: RoutinesPage()),
  ];

  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              bottom: _tabBarHeight + AppSpace.xl,
            ),
            child: IndexedStack(
              index: _currentIndex,
              children: [
                for (final tab in _tabs)
                  CupertinoTabView(
                    builder: (_) => tab.page,
                  ),
              ],
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(
              AppSpace.l,
              AppSpace.s,
              AppSpace.l,
              AppSpace.l,
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _FloatingTabBar(
                height: _tabBarHeight,
                currentIndex: _currentIndex,
                labels: _tabs.map((tab) => tab.label).toList(),
                onChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.label,
    required this.page,
  });

  final String label;
  final Widget page;
}

class _FloatingTabBar extends StatefulWidget {
  const _FloatingTabBar({
    required this.height,
    required this.currentIndex,
    required this.labels,
    required this.onChanged,
  });

  final double height;
  final int currentIndex;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  State<_FloatingTabBar> createState() => _FloatingTabBarState();
}

class _FloatingTabBarState extends State<_FloatingTabBar> {
  double? _dragLeft;
  double? _tapPreviewLeft;

  double _leftForIndex({
    required int index,
    required double inset,
    required double segmentWidth,
  }) {
    return segmentWidth * index + inset;
  }

  double _clampLeft({
    required double desiredLeft,
    required double inset,
    required double maxLeft,
  }) {
    return desiredLeft.clamp(inset, maxLeft);
  }

  @override
  Widget build(BuildContext context) {
    final barColor = CupertinoDynamicColor.resolve(
      AppColor.secondarySystemGroupedBackground,
      context,
    );
    final activeColor = CupertinoDynamicColor.resolve(
      AppColor.systemBackground,
      context,
    );
    final inactiveText = CupertinoDynamicColor.resolve(
      AppColor.secondaryLabel,
      context,
    );
    final activeText = CupertinoDynamicColor.resolve(
      AppColor.accent,
      context,
    );

    return ClipRRect(
      borderRadius: AppRadius.pill,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: widget.height,
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpace.xs),
          decoration: BoxDecoration(
            color: barColor.withOpacity(0.75),
            borderRadius: AppRadius.pill,
            border: Border.all(
              color: CupertinoDynamicColor.resolve(AppColor.separator, context),
              width: 0.5,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final segmentWidth = constraints.maxWidth / widget.labels.length;
              const double inset = 0;
              final thumbWidth = segmentWidth - (inset * 2);
              final maxLeft = constraints.maxWidth - thumbWidth - inset;

              final double left = _clampLeft(
                desiredLeft: _dragLeft ??
                    _tapPreviewLeft ??
                    _leftForIndex(
                      index: widget.currentIndex,
                      inset: inset,
                      segmentWidth: segmentWidth,
                    ),
                inset: inset,
                maxLeft: maxLeft,
              );

              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: (details) {
                  final desiredLeft = details.localPosition.dx - thumbWidth / 2;
                  setState(() {
                    _tapPreviewLeft = _clampLeft(
                      desiredLeft: desiredLeft,
                      inset: inset,
                      maxLeft: maxLeft,
                    );
                    _dragLeft = null;
                  });
                },
                onTapUp: (details) {
                  final tapX = details.localPosition.dx;
                  final targetIndex = (tapX / segmentWidth)
                      .clamp(0, widget.labels.length - 1)
                      .floor();
                  setState(() {
                    _tapPreviewLeft = _leftForIndex(
                      index: targetIndex,
                      inset: inset,
                      segmentWidth: segmentWidth,
                    );
                    _dragLeft = null;
                  });
                  if (targetIndex != widget.currentIndex) {
                    widget.onChanged(targetIndex);
                  }
                },
                onTapCancel: () {
                  setState(() {
                    _tapPreviewLeft = null;
                    _dragLeft = null;
                  });
                },
                onHorizontalDragStart: (details) {
                  setState(() {
                    _tapPreviewLeft = null;
                    final desiredLeft =
                        details.localPosition.dx - thumbWidth / 2;
                    _dragLeft = _clampLeft(
                      desiredLeft: desiredLeft,
                      inset: inset,
                      maxLeft: maxLeft,
                    );
                  });
                },
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    final desiredLeft =
                        (_dragLeft ?? inset) + details.delta.dx;
                    _dragLeft = _clampLeft(
                      desiredLeft: desiredLeft,
                      inset: inset,
                      maxLeft: maxLeft,
                    );
                  });
                },
                onHorizontalDragEnd: (_) {
                  final currentLeft = left;
                  final thumbCenter = currentLeft + thumbWidth / 2;
                  final targetIndex = (thumbCenter / segmentWidth)
                      .floor()
                      .clamp(0, widget.labels.length - 1);
                  setState(() {
                    _tapPreviewLeft = _leftForIndex(
                      index: targetIndex,
                      inset: inset,
                      segmentWidth: segmentWidth,
                    );
                    _dragLeft = null;
                  });
                  if (targetIndex != widget.currentIndex) {
                    widget.onChanged(targetIndex);
                  }
                },
                onLongPressStart: (details) {
                  setState(() {
                    final desiredLeft =
                        details.localPosition.dx - thumbWidth / 2;
                    _dragLeft = _clampLeft(
                      desiredLeft: desiredLeft,
                      inset: inset,
                      maxLeft: maxLeft,
                    );
                  });
                },
                onLongPressMoveUpdate: (details) {
                  setState(() {
                    final desiredLeft =
                        details.localPosition.dx - thumbWidth / 2;
                    _dragLeft = _clampLeft(
                      desiredLeft: desiredLeft,
                      inset: inset,
                      maxLeft: maxLeft,
                    );
                  });
                },
                onLongPressEnd: (_) {
                  final currentLeft = left;
                  final thumbCenter = currentLeft + thumbWidth / 2;
                  final targetIndex = (thumbCenter / segmentWidth)
                      .floor()
                      .clamp(0, widget.labels.length - 1);
                  setState(() {
                    _dragLeft = null;
                  });
                  if (targetIndex != widget.currentIndex) {
                    widget.onChanged(targetIndex);
                  }
                },
                onHorizontalDragCancel: () {
                  setState(() {
                    _tapPreviewLeft = null;
                    _dragLeft = null;
                  });
                },
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration:
                          _dragLeft == null ? AppMotion.quick : Duration.zero,
                      curve: Curves.easeOut,
                      top: inset,
                      bottom: inset,
                      left: left,
                      width: thumbWidth,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: activeColor,
                          borderRadius: AppRadius.pill,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var index = 0;
                            index < widget.labels.length;
                            index++)
                          Expanded(
                            child: Center(
                              child: Text(
                                widget.labels[index],
                                style:
                                    AppTextStyle.footnote(context).copyWith(
                                  color: index == widget.currentIndex
                                      ? activeText
                                      : inactiveText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
