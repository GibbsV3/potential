import 'package:flutter/cupertino.dart';

class AppTextStyle {
  const AppTextStyle._();

  static TextStyle largeTitle(BuildContext context) {
    return CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle;
  }

  static TextStyle title1(BuildContext context) {
    return CupertinoTheme.of(context).textTheme.navTitleTextStyle;
  }

  static TextStyle title3(BuildContext context) {
    final base = CupertinoTheme.of(context).textTheme.textStyle;
    return base.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    );
  }

  static TextStyle body(BuildContext context) {
    return CupertinoTheme.of(context).textTheme.textStyle;
  }

  static TextStyle footnote(BuildContext context) {
    return CupertinoTheme.of(context).textTheme.tabLabelTextStyle;
  }

  static TextStyle caption(BuildContext context) {
    return CupertinoTheme.of(context).textTheme.actionTextStyle;
  }
}
