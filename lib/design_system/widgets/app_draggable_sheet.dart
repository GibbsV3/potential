import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'package:potential/potential.dart';

/// Draggable Cupertino sheet with a standard header and pull-to-dismiss gesture.
class AppDraggableSheet extends StatefulWidget {
  const AppDraggableSheet({
    super.key,
    required this.title,
    required this.child,
    this.cancelLabel = 'Cancel',
    this.onCancel,
    this.primaryLabel,
    this.onPrimary,
    this.primaryEnabled = true,
    this.backgroundColor,
  });

  final String title;
  final Widget child;
  final String cancelLabel;
  final VoidCallback? onCancel;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final bool primaryEnabled;
  final Color? backgroundColor;

  @override
  State<AppDraggableSheet> createState() => _AppDraggableSheetState();
}

class _AppDraggableSheetState extends State<AppDraggableSheet> {
  double? _dragStartY;
  double _dragExtent = 0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final background = CupertinoDynamicColor.resolve(
      widget.backgroundColor ?? AppColor.systemBackground,
      context,
    );
    final media = MediaQuery.of(context);
    final sheetHeight = media.size.height - media.padding.top;
    final currentHeight =
        (sheetHeight - _dragExtent).clamp(sheetHeight * 0.2, sheetHeight);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: AnimatedContainer(
        duration: _isDragging ? Duration.zero : AppMotion.quick,
        height: currentHeight,
        child: CupertinoPopupSurface(
          isSurfacePainted: true,
          child: AnimatedPadding(
            duration: AppMotion.quick,
            padding: EdgeInsets.only(
              bottom: media.viewInsets.bottom,
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: DecoratedBox(
                decoration: BoxDecoration(color: background),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpace.l,
                          AppSpace.m,
                          AppSpace.l,
                          AppSpace.s,
                        ),
                        child: GestureDetector(
                          behavior: HitTestBehavior.deferToChild,
                          onVerticalDragStart: (details) {
                            _dragStartY = details.globalPosition.dy;
                            _dragExtent = 0;
                            _isDragging = true;
                          },
                          onVerticalDragUpdate: (details) {
                            if (_dragStartY == null) return;
                            final delta =
                                details.globalPosition.dy - _dragStartY!;
                            if (delta <= 0) {
                              return;
                            }
                            setState(() {
                              _dragExtent =
                                  delta.clamp(0, sheetHeight).toDouble();
                              _isDragging = true;
                            });
                          },
                          onVerticalDragCancel: () {
                            _dragStartY = null;
                            setState(() {
                              _dragExtent = 0;
                              _isDragging = false;
                            });
                          },
                          onVerticalDragEnd: (details) {
                            final velocity = details.primaryVelocity ?? 0;
                            final dismissByVelocity = velocity > 900;
                            final updatedCurrentHeight =
                                (sheetHeight - _dragExtent)
                                    .clamp(sheetHeight * 0.2, sheetHeight);
                            final shouldDismiss =
                                updatedCurrentHeight < sheetHeight * 0.4;
                            if (shouldDismiss || dismissByVelocity) {
                              HapticFeedback.selectionClick();
                              _dismiss();
                            } else {
                              setState(() {
                                _dragExtent = 0;
                                _isDragging = false;
                              });
                            }
                            _dragStartY = null;
                            _isDragging = false;
                          },
                          child: Row(
                            children: [
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  _dismiss();
                                },
                                child: Text(widget.cancelLabel),
                              ),
                              Expanded(
                                child: Text(
                                  widget.title,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyle.title3(context).copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              _PrimaryButton(
                                label: widget.primaryLabel,
                                enabled: widget.primaryEnabled,
                                onPressed: widget.onPrimary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(child: widget.child),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _dismiss() {
    final handled = widget.onCancel;
    if (handled != null) {
      handled();
      return;
    }
    Navigator.of(context).maybePop();
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String? label;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return const SizedBox(width: 60);
    }
    final accent = CupertinoDynamicColor.resolve(
      AppColor.accent,
      context,
    );
    final secondary = CupertinoDynamicColor.resolve(
      AppColor.secondaryLabel,
      context,
    );
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: enabled ? onPressed : null,
      child: Text(
        label!,
        style: AppTextStyle.body(context).copyWith(
          fontWeight: FontWeight.w600,
          color: enabled ? accent : secondary,
        ),
      ),
    );
  }
}
