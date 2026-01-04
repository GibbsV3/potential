import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/dashboard_repository.dart';
import '../../../core/domain/routine.dart';
import '../../../core/domain/weekday.dart';
import '../../../design_system/design_system.dart';
import 'bloc/routines_bloc.dart';

class RoutinesPage extends StatelessWidget {
  const RoutinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RoutinesBloc(
        context.read<DashboardRepository>(),
      )..add(const RoutinesLoaded()),
      child: const _RoutinesView(),
    );
  }
}

class _RoutinesView extends StatelessWidget {
  const _RoutinesView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutinesBloc, RoutinesState>(
      builder: (context, state) {
        return CupertinoPageScaffold(
          child: CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: const Text('Routines'),
                leading: _EditButton(
                  isEditing: state.isEditing,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.read<RoutinesBloc>().add(
                          const RoutinesEditToggled(),
                        );
                  },
                ),
                trailing: _AddButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.pushNamed('routine_new');
                  },
                ),
              ),
              if (state.status == RoutinesStatus.loading)
                const SliverFillRemaining(
                  child: Center(child: CupertinoActivityIndicator()),
                )
              else if (state.status == RoutinesStatus.failure)
                SliverFillRemaining(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.l,
                    ),
                    child: Center(
                      child: Text(
                        state.errorMessage ?? 'Something went wrong.',
                        style: AppTextStyle.body(context).copyWith(
                          color: CupertinoDynamicColor.resolve(
                            AppColor.secondaryLabel,
                            context,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else if (state.routines.isEmpty)
                SliverFillRemaining(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.l,
                    ),
                    child: Center(
                      child: Text(
                        'No routines yet.\nAdd one to start tracking your days.',
                        style: AppTextStyle.body(context).copyWith(
                          color: CupertinoDynamicColor.resolve(
                            AppColor.secondaryLabel,
                            context,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.l,
                    AppSpace.s,
                    AppSpace.l,
                    AppSpace.xxxl,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final routine = state.routines[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == state.routines.length - 1
                                ? 0
                                : AppSpace.m,
                          ),
                          child: _RoutineCard(
                            routine: routine,
                            isEditing: state.isEditing,
                            onToggle: (isOn) {
                              HapticFeedback.selectionClick();
                              context.read<RoutinesBloc>().add(
                                    RoutineActivationChanged(
                                      routineId: routine.id,
                                      isActive: isOn,
                                    ),
                                  );
                            },
                            onDelete: () {
                              HapticFeedback.mediumImpact();
                              context.read<RoutinesBloc>().add(
                                    RoutineDeleted(routine.id),
                                  );
                            },
                            onTap: () {
                              HapticFeedback.selectionClick();
                              context.pushNamed(
                                'routine_edit',
                                pathParameters: {'id': routine.id},
                              );
                            },
                          ),
                        );
                      },
                      childCount: state.routines.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({
    required this.isEditing,
    required this.onPressed,
  });

  final bool isEditing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = isEditing ? 'Done' : 'Edit';
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: const Icon(CupertinoIcons.add),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    required this.routine,
    required this.isEditing,
    required this.onToggle,
    required this.onDelete,
    this.onTap,
  });

  final Routine routine;
  final bool isEditing;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final background = CupertinoDynamicColor.resolve(
      AppColor.secondarySystemGroupedBackground,
      context,
    );
    final label = CupertinoDynamicColor.resolve(AppColor.label, context);
    final secondary =
        CupertinoDynamicColor.resolve(AppColor.secondaryLabel, context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.quick,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.card,
        ),
        padding: const EdgeInsets.all(AppSpace.m),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: AppMotion.quick,
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeOut,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axis: Axis.horizontal,
                    child: child,
                  ),
                );
              },
              child: isEditing
                  ? Padding(
                      key: const ValueKey('delete'),
                      padding: const EdgeInsets.only(right: AppSpace.s),
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 28,
                        onPressed: onDelete,
                        child: const Icon(
                          CupertinoIcons.minus_circle_fill,
                          color: CupertinoColors.systemRed,
                          size: 24,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(
                      key: ValueKey('spacer'),
                    ),
            ),
            Expanded(
              child: AnimatedPadding(
                duration: AppMotion.quick,
                curve: Curves.easeOut,
                padding: EdgeInsets.only(left: isEditing ? AppSpace.s : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.title,
                      style: AppTextStyle.body(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: label,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      _formatWeekdays(routine.weekdays),
                      style: AppTextStyle.footnote(context).copyWith(
                        color: secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            CupertinoSwitch(
              value: routine.isActive,
              onChanged: onToggle,
              activeColor: CupertinoDynamicColor.resolve(
                AppColor.accent,
                context,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatWeekdays(Set<Weekday> weekdays) {
  if (weekdays.length == Weekday.values.length) {
    return 'Every day';
  }
  final sorted = weekdays.toList()
    ..sort((a, b) => a.number.compareTo(b.number));
  return sorted.map((day) => day.shortLabel).join(', ');
}
