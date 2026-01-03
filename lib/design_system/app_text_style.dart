import 'package:flutter/cupertino.dart';

class AppTextStyle {
  const AppTextStyle._();

  static TextStyle largeTitle(BuildContext context) {
    return CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle;
  }

  static TextStyle title1(BuildContext context) {
    return CupertinoTheme.of(context).textTheme.navTitleTextStyle;
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
