import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/reusable_widgets.dart';

class AdminRedemptionMgmtPage extends StatelessWidget {
  const AdminRedemptionMgmtPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDarkDeep,
      appBar: AppBar(
        title: const HeadingText('إدارة المزايا الملكية'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: BodyText('هذا القسم قيد التحديث للامتثال للمعايير الجديدة.'),
      ),
    );
  }
}
