import 'dart:ui';

import 'package:flutter/cupertino.dart';

import 'package:potential/potential.dart';

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

class _FloatingTabBar extends StatelessWidget {
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
          height: height,
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpace.xs),
          decoration: BoxDecoration(
            color: barColor.withValues(alpha: 0.75),
            borderRadius: AppRadius.pill,
            border: Border.all(
              color: CupertinoDynamicColor.resolve(AppColor.separator, context),
              width: 0.5,
            ),
          ),
          child: AppSlidingSegmentedControl<int>(
            segments: [
              for (var index = 0; index < labels.length; index++)
                AppSlidingSegment<int>(
                  value: index,
                  builder: (context, isSelected) => Text(
                    labels[index],
                    style: AppTextStyle.footnote(context).copyWith(
                      color: isSelected ? activeText : inactiveText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
            value: currentIndex,
            onChanged: onChanged,
            backgroundColor: CupertinoColors.transparent,
            thumbColor: activeColor,
            thumbInset: 0,
          ),
        ),
      ),
    );
  }
}
