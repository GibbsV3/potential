import 'package:flutter/cupertino.dart';

import 'package:potential/potential.dart';

class AppSlidingSegment<T> {
  const AppSlidingSegment({
    required this.value,
    required this.builder,
  });

  final T value;
  final Widget Function(BuildContext context, bool isSelected) builder;
}

/// Cupertino-style segmented control with draggable/tap-preview thumb.
class AppSlidingSegmentedControl<T> extends StatefulWidget {
  const AppSlidingSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.backgroundColor,
    this.thumbColor,
    this.padding = EdgeInsets.zero,
    this.thumbInset = 0,
  });

  final List<AppSlidingSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final Color? backgroundColor;
  final Color? thumbColor;
  final EdgeInsetsGeometry padding;
  final double thumbInset;

  @override
  State<AppSlidingSegmentedControl<T>> createState() =>
      _AppSlidingSegmentedControlState<T>();
}

class _AppSlidingSegmentedControlState<T>
    extends State<AppSlidingSegmentedControl<T>> {
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
    final resolvedBackground = widget.backgroundColor == null
        ? null
        : CupertinoDynamicColor.resolve(widget.backgroundColor!, context);
    final resolvedThumb = widget.thumbColor == null
        ? CupertinoDynamicColor.resolve(AppColor.systemBackground, context)
        : widget.thumbColor!;

    return ClipRRect(
      borderRadius: AppRadius.pill,
      child: Container(
        color: resolvedBackground,
        padding: widget.padding,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final segmentWidth = constraints.maxWidth / widget.segments.length;
            final double inset = widget.thumbInset;
            final thumbWidth = segmentWidth - (inset * 2);
            final maxLeft = constraints.maxWidth - thumbWidth - inset;

            final selectedIndex = widget.segments
                .indexWhere((segment) => segment.value == widget.value);
            final resolvedIndex = selectedIndex < 0 ? 0 : selectedIndex;

            final double left = _clampLeft(
              desiredLeft: _dragLeft ??
                  _tapPreviewLeft ??
                  _leftForIndex(
                    index: resolvedIndex,
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
                    .clamp(0, widget.segments.length - 1)
                    .floor();
                final targetLeft = _leftForIndex(
                  index: targetIndex,
                  inset: inset,
                  segmentWidth: segmentWidth,
                );
                setState(() {
                  _tapPreviewLeft = targetLeft;
                  _dragLeft = null;
                });
                final targetValue = widget.segments[targetIndex].value;
                if (targetValue != widget.value) {
                  widget.onChanged(targetValue);
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
                  final desiredLeft = details.localPosition.dx - thumbWidth / 2;
                  _dragLeft = _clampLeft(
                    desiredLeft: desiredLeft,
                    inset: inset,
                    maxLeft: maxLeft,
                  );
                });
              },
              onHorizontalDragUpdate: (details) {
                setState(() {
                  final desiredLeft = (_dragLeft ?? inset) + details.delta.dx;
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
                    .clamp(0, widget.segments.length - 1);
                setState(() {
                  _tapPreviewLeft = _leftForIndex(
                    index: targetIndex,
                    inset: inset,
                    segmentWidth: segmentWidth,
                  );
                  _dragLeft = null;
                });
                final targetValue = widget.segments[targetIndex].value;
                if (targetValue != widget.value) {
                  widget.onChanged(targetValue);
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
                        color: resolvedThumb,
                        borderRadius: AppRadius.pill,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var index = 0;
                          index < widget.segments.length;
                          index++)
                        Expanded(
                          child: Center(
                            child: widget.segments[index].builder(
                              context,
                              widget.segments[index].value == widget.value,
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
    );
  }
}
