import 'package:flutter/cupertino.dart';
import 'package:potential/potential.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await DashboardLocalStore.open();
  final repository = LocalDashboardRepository(store);
  runApp(PotentialApp(repository: repository));
}
