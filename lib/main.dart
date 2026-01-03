import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'features/dashboard/data/dashboard_local_store.dart';
import 'features/dashboard/data/local_dashboard_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final repository = LocalDashboardRepository(DashboardLocalStore(prefs));
  runApp(PotentialApp(repository: repository));
}
