import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/data/dashboard_repository.dart';
import '../design_system/design_system.dart';
import 'router.dart';

class PotentialApp extends StatelessWidget {
  const PotentialApp({
    super.key,
    required this.repository,
  });

  final DashboardRepository repository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: repository,
      child: CupertinoApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        routerConfig: AppRouter.build(),
      ),
    );
  }
}
