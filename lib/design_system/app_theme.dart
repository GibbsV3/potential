import 'package:flutter/cupertino.dart';

import 'package:potential/potential.dart';

class AppTheme {
  const AppTheme._();

  static CupertinoThemeData dark() {
    // Use semantic colors for native iOS contrast in forced dark mode.
    return const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColor.accent,
      barBackgroundColor: AppColor.systemBackground,
      scaffoldBackgroundColor: AppColor.systemGroupedBackground,
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColor.label,
      ),
    );
  }
}
