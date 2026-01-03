import 'package:flutter/cupertino.dart';

import '../../../design_system/design_system.dart';

class RoutinesPage extends StatelessWidget {
  const RoutinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Routines'),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.l),
              child: Center(
                child: Text(
                  'Create and edit routines here.',
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
