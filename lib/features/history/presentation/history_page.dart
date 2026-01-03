import 'package:flutter/cupertino.dart';

import '../../../design_system/design_system.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('History'),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.l),
              child: Center(
                child: Text(
                  'Calendar view coming soon.',
                  style: AppTextStyle.body(context).copyWith(
                    color: CupertinoDynamicColor.resolve(
                      AppColor.secondaryLabel,
                      context,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
