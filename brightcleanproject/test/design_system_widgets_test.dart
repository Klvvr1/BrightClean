import 'package:brightcleanproject/core/theme/app_colors.dart';
import 'package:brightcleanproject/core/theme/app_theme.dart';
import 'package:brightcleanproject/core/widgets/app_empty_state.dart';
import 'package:brightcleanproject/core/widgets/app_section_title.dart';
import 'package:brightcleanproject/core/widgets/app_stat_card.dart';
import 'package:brightcleanproject/core/widgets/app_status_badge.dart';
import 'package:brightcleanproject/core/widgets/app_surface_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget themedHarness(Widget child, {ThemeMode themeMode = ThemeMode.light}) {
    return Builder(
      builder: (context) {
        return MaterialApp(
          theme: AppTheme.getLightTheme(context),
          darkTheme: AppTheme.getDarkTheme(context),
          themeMode: themeMode,
          home: Scaffold(body: Center(child: child)),
        );
      },
    );
  }

  testWidgets('shared design widgets render in light theme', (tester) async {
    await tester.pumpWidget(
      themedHarness(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            AppSectionTitle(title: 'العنوان', subtitle: 'وصف قصير'),
            AppSurfaceCard(child: Text('card')),
            AppStatusBadge(label: 'نشط', color: AppColors.success),
            AppStatCard(
              title: 'الطلبات',
              value: '12',
              icon: Icons.receipt_long_outlined,
            ),
            AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'لا توجد بيانات',
              message: 'ستظهر العناصر هنا لاحقاً',
            ),
          ],
        ),
      ),
    );

    expect(find.text('العنوان'), findsOneWidget);
    expect(find.text('card'), findsOneWidget);
    expect(find.text('نشط'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('لا توجد بيانات'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared design widgets render in dark theme', (tester) async {
    await tester.pumpWidget(
      themedHarness(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSurfaceCard(child: Text('dark card')),
            AppStatusBadge(label: 'تحذير', color: AppColors.warning),
            AppStatCard(
              title: 'الإيرادات',
              value: '500',
              icon: Icons.account_balance_wallet_outlined,
              emphasis: true,
            ),
          ],
        ),
        themeMode: ThemeMode.dark,
      ),
    );

    expect(find.text('dark card'), findsOneWidget);
    expect(find.text('تحذير'), findsOneWidget);
    expect(find.text('500'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
