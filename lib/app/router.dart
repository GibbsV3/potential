import 'package:go_router/go_router.dart';

import 'tabs_page.dart';

class AppRouter {
  const AppRouter._();

  static GoRouter build() {
    return GoRouter(
      routes: [
        GoRoute(
          path: '/',
          name: 'root',
          builder: (context, state) => const TabsPage(),
        ),
      ],
    );
  }
}
