import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/dashboard_repository.dart';
import '../../../core/domain/routine_importance.dart';
import '../../../core/domain/weekday.dart';
import '../../../design_system/design_system.dart';
import 'edit_routine_bloc.dart';

class EditRoutinePage extends StatelessWidget {
  const EditRoutinePage({
    super.key,
    this.routineId,
  });

  final String? routineId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditRoutineBloc(
        context.read<DashboardRepository>(),
      )..add(EditRoutineStarted(routineId)),
      child: const _EditRoutineView(),
    );
  }
}

class _EditRoutineView extends StatelessWidget {
  const _EditRoutineView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<EditRoutineBloc, EditRoutineState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == EditRoutineStatus.success,
      listener: (context, state) {
        HapticFeedback.mediumImpact();
        context.pop();
      },
      child: BlocBuilder<EditRoutineBloc, EditRoutineState>(
        builder: (context, state) {
          final accentColor =
              CupertinoDynamicColor.resolve(AppColor.accent, context);
          final disabledColor =
              CupertinoDynamicColor.resolve(AppColor.secondaryLabel, context);
          final canSave =
              state.canSave && state.status != EditRoutineStatus.saving;

          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: const Text('Edit Routine'),
              leading: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  context.pop();
                },
                child: const Text('Cancel'),
              ),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: canSave
                    ? () {
                        HapticFeedback.mediumImpact();
                        context
                            .read<EditRoutineBloc>()
                            .add(const EditRoutineSaved());
                      }
                    : null,
                child: Text(
                  'Save',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: canSave ? accentColor : disabledColor,
                  ),
                ),
              ),
            ),
            child: SafeArea(
              child: _buildBody(state),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(EditRoutineState state) {
    if (state.status == EditRoutineStatus.loading ||
        state.status == EditRoutineStatus.initial) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (state.status == EditRoutineStatus.failure) {
      return _ErrorState(message: state.errorMessage);
    }
    return const _EditRoutineForm();
  }
}

class _EditRoutineForm extends StatefulWidget {
  const _EditRoutineForm();

  @override
  State<_EditRoutineForm> createState() => _EditRoutineFormState();
}

class _EditRoutineFormState extends State<_EditRoutineForm> {
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EditRoutineBloc, EditRoutineState>(
      listenWhen: (previous, current) =>
          previous.title != current.title ||
          previous.status != current.status,
      listener: (context, state) => _syncControllers(state),
      child: BlocBuilder<EditRoutineBloc, EditRoutineState>(
        builder: (context, state) {
          if (state.status == EditRoutineStatus.ready ||
              state.status == EditRoutineStatus.saving) {
            _syncControllers(state);
          }

          return CupertinoScrollbar(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.l,
                AppSpace.l,
                AppSpace.l,
                AppSpace.xxxl,
              ),
              children: [
                _buildDetailsSection(context, state),
                const SizedBox(height: AppSpace.l),
                _buildImportanceSection(context, state),
                const SizedBox(height: AppSpace.l),
                _buildWeekdaySection(context, state),
                const SizedBox(height: AppSpace.l),
                _buildTasksSection(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailsSection(
    BuildContext context,
    EditRoutineState state,
  ) {
    return CupertinoFormSection.insetGrouped(
      backgroundColor: CupertinoDynamicColor.resolve(
        AppColor.systemGroupedBackground,
        context,
      ),
      children: [
        CupertinoTextFormFieldRow(
          controller: _titleController,
          placeholder: 'Routine name',
          prefix: const Text('Name'),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.l,
          ),
          onChanged: (value) {
            context.read<EditRoutineBloc>().add(
                  EditRoutineTitleChanged(value),
                );
          },
        ),
      ],
    );
  }

  Widget _buildImportanceSection(
    BuildContext context,
    EditRoutineState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.l,
            AppSpace.s,
            AppSpace.l,
            AppSpace.xs,
          ),
        child: Text(
          'Importance',
          style: AppTextStyle.body(context).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.l,
            vertical: AppSpace.m,
          ),
          child: _ImportanceSelector(
            value: state.importance,
            onChanged: (importance) {
              if (importance != null) {
                HapticFeedback.selectionClick();
                context.read<EditRoutineBloc>().add(
                      EditRoutineImportanceChanged(importance),
                    );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdaySection(
    BuildContext context,
    EditRoutineState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.l,
            AppSpace.s,
            AppSpace.l,
            AppSpace.xs,
          ),
        child: Text(
          'Days of the Week',
          style: AppTextStyle.body(context).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.l,
            vertical: AppSpace.s,
          ),
          child: Wrap(
            spacing: AppSpace.s,
            runSpacing: AppSpace.s,
            children: [
              for (final weekday in _sundayFirstWeekdays)
                _WeekdayChip(
                  label: weekday.shortLabel,
                  isSelected: state.weekdays.contains(weekday),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<EditRoutineBloc>().add(
                          EditRoutineWeekdayToggled(weekday),
                        );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTasksSection(
    BuildContext context,
    EditRoutineState state,
  ) {
    final bloc = context.read<EditRoutineBloc>();
    final cardColor = CupertinoDynamicColor.resolve(
      AppColor.secondarySystemGroupedBackground,
      context,
    );
    final dividerColor =
        CupertinoDynamicColor.resolve(AppColor.separator, context);

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpace.l,
        right: AppSpace.l,
        bottom: AppSpace.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Tasks',
                style: AppTextStyle.body(context).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 28,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _showTaskSheet(context, bloc, isEditing: false);
                },
                child: Icon(
                  CupertinoIcons.add,
                  size: 20,
                  color: CupertinoDynamicColor.resolve(
                    AppColor.accent,
                    context,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: AppRadius.card,
            ),
            child: Column(
              children: [
                if (state.tasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.l,
                      vertical: AppSpace.m,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Add tasks to build your routine.',
                        style: AppTextStyle.footnote(context).copyWith(
                          color: CupertinoDynamicColor.resolve(
                            AppColor.secondaryLabel,
                            context,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  for (var i = 0; i < state.tasks.length; i++) ...[
                    Dismissible(
                      key: ValueKey(state.tasks[i].id),
                      direction: DismissDirection.startToEnd,
                      background: Container(
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemRed.withOpacity(0.15),
                          borderRadius: i == 0 && i == state.tasks.length - 1
                              ? AppRadius.card
                              : BorderRadius.only(
                                  topLeft: i == 0
                                      ? AppRadius.card.topLeft
                                      : Radius.zero,
                                  topRight: i == 0
                                      ? AppRadius.card.topRight
                                      : Radius.zero,
                                  bottomLeft: i == state.tasks.length - 1
                                      ? AppRadius.card.bottomLeft
                                      : Radius.zero,
                                  bottomRight: i == state.tasks.length - 1
                                      ? AppRadius.card.bottomRight
                                      : Radius.zero,
                                ),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: AppSpace.l),
                        child: const Icon(
                          CupertinoIcons.delete_solid,
                          color: CupertinoColors.systemRed,
                        ),
                      ),
                      onDismissed: (_) {
                        HapticFeedback.lightImpact();
                        bloc.add(
                          EditRoutineTaskRemoved(state.tasks[i].id),
                        );
                      },
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _showTaskSheet(
                          context,
                          bloc,
                          isEditing: true,
                        ),
                        onLongPress: () => _showDeleteTaskMenu(
                          context,
                          bloc,
                          state.tasks[i].id,
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppSpace.l,
                            AppSpace.m,
                            AppSpace.s,
                            AppSpace.m,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                              child: Text(
                                state.tasks[i].title.isEmpty
                                    ? 'Task ${i + 1}'
                                    : state.tasks[i].title,
                                style: AppTextStyle.body(context).copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                              Icon(
                                CupertinoIcons.chevron_forward,
                                size: 16,
                                color: CupertinoDynamicColor.resolve(
                                  AppColor.secondaryLabel,
                                  context,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (i != state.tasks.length - 1)
                      Container(
                        height: 0.5,
                        margin: EdgeInsets.only(
                          left: AppSpace.l,
                          right: AppSpace.l,
                        ),
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

  void _syncControllers(EditRoutineState state) {
    if (_titleController.text != state.title) {
      _titleController.text = state.title;
    }
  }
}

class _ImportanceSelector extends StatelessWidget {
  const _ImportanceSelector({
    required this.value,
    required this.onChanged,
  });

  final RoutineImportance value;
  final ValueChanged<RoutineImportance?> onChanged;

  @override
  Widget build(BuildContext context) {
    final resolvedAccent =
        CupertinoDynamicColor.resolve(AppColor.accent, context);
    final neutral =
        CupertinoDynamicColor.resolve(AppColor.secondaryLabel, context);
    final labelColor =
        CupertinoDynamicColor.resolve(AppColor.secondaryLabel, context);

    return Row(
      children: [
        Text(
          'Least',
          style: AppTextStyle.footnote(context).copyWith(
            color: labelColor,
          ),
        ),
        const SizedBox(width: AppSpace.m),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final option in RoutineImportance.values)
                _ImportanceDot(
                  isSelected: value == option,
                  size: 22,
                  color: _colorFor(option, resolvedAccent, neutral),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(option);
                  },
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpace.m),
        Text(
          'Most',
          style: AppTextStyle.footnote(context).copyWith(
            color: labelColor,
          ),
        ),
      ],
    );
  }

  Color _colorFor(
    RoutineImportance importance,
    Color accent,
    Color neutral,
  ) {
    final intensity = importance.level / RoutineImportance.values.last.level;
    return Color.lerp(neutral, accent, intensity.clamp(0, 1)) ?? accent;
  }
}

class _ImportanceDot extends StatelessWidget {
  const _ImportanceDot({
    required this.isSelected,
    required this.size,
    required this.color,
    required this.onTap,
  });

  final bool isSelected;
  final double size;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final resolvedBackground =
        CupertinoDynamicColor.resolve(AppColor.systemBackground, context);
    final fillColor = isSelected ? color : resolvedBackground;
    final borderColor = color;
    final borderWidth = isSelected ? 0.0 : 1.5;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: fillColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
        ),
      ),
    );
  }
}

class _WeekdayChip extends StatelessWidget {
  const _WeekdayChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = CupertinoDynamicColor.resolve(
      isSelected
          ? AppColor.accent
          : AppColor.secondarySystemGroupedBackground,
      context,
    );
    final foreground = CupertinoDynamicColor.resolve(
      isSelected ? AppColor.systemBackground : AppColor.label,
      context,
    );
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.m,
        vertical: AppSpace.s,
      ),
      minSize: 32,
      borderRadius: AppRadius.pill,
      color: background,
      onPressed: onTap,
      child: Text(
        label,
        style: AppTextStyle.body(context).copyWith(
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.l),
        child: Text(
          message ?? 'Something went wrong.',
          textAlign: TextAlign.center,
          style: AppTextStyle.body(context).copyWith(
            color: CupertinoDynamicColor.resolve(
              AppColor.secondaryLabel,
              context,
            ),
          ),
        ),
      ),
    );
  }
}

const List<Weekday> _sundayFirstWeekdays = [
  Weekday.sunday,
  Weekday.monday,
  Weekday.tuesday,
  Weekday.wednesday,
  Weekday.thursday,
  Weekday.friday,
  Weekday.saturday,
];

void _showTaskSheet(
  BuildContext context,
  EditRoutineBloc bloc, {
  required bool isEditing,
}) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (context) {
      return CupertinoActionSheet(
        title: Text(isEditing ? 'Edit Task' : 'New Task'),
        message: Text(
          'Task ${isEditing ? 'editing' : 'creation'} flow is coming soon.',
        ),
        actions: [
          CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              HapticFeedback.mediumImpact();
              if (!isEditing) {
                bloc.add(const EditRoutineTaskAdded());
              }
              Navigator.of(context).pop();
            },
            child: Text(isEditing ? 'OK' : 'Add Task'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      );
    },
  );
}

void _showDeleteTaskMenu(
  BuildContext context,
  EditRoutineBloc bloc,
  String taskId,
) {
  HapticFeedback.mediumImpact();
  showCupertinoModalPopup<void>(
    context: context,
    builder: (context) {
      return CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              bloc.add(EditRoutineTaskRemoved(taskId));
              Navigator.of(context).pop();
            },
            child: const Text('Delete Task'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      );
    },
  );
}
