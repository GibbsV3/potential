import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import 'tabs_page.dart';
import '../features/routine_edit/presentation/edit_routine_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  const AppRouter._();

  static GoRouter build() {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      routes: [
        GoRoute(
          path: '/',
          name: 'root',
          builder: (context, state) => const TabsPage(),
          routes: [
            GoRoute(
              parentNavigatorKey: _rootNavigatorKey,
              path: 'routines/new',
              name: 'routine_new',
              builder: (context, state) => const EditRoutinePage(),
            ),
            GoRoute(
              parentNavigatorKey: _rootNavigatorKey,
              path: 'routines/:id/edit',
              name: 'routine_edit',
              builder: (context, state) {
                final id = state.pathParameters['id'];
                return EditRoutinePage(
                  routineId: id ?? '',
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
