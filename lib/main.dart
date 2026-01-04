import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:potential/potential.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final repository = LocalDashboardRepository(DashboardLocalStore(prefs));
  runApp(PotentialApp(repository: repository));
}
