import 'package:flutter/cupertino.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      home: CupertinoPageScaffold(
        child: Center(
          child: Text('Hello World!'),
        ),
      ),
    );
  }
}
