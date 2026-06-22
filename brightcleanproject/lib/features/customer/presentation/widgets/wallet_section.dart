import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_styles.dart';
import '../wallet_details_screen.dart';

class WalletSection extends StatelessWidget {
  final String balance;
  final VoidCallback? onDepositSuccess;

  const WalletSection({super.key, required this.balance, this.onDepositSuccess});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: AppStyles.surface(context),
      clipBehavior: Clip.hardEdge,
      child: ListTile(
        leading: Icon(Icons.account_balance_wallet, color: theme.colorScheme.primary),
        title: Text('المحفظة / النقاط', style: theme.textTheme.titleMedium),
        trailing: Text(
          balance,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.success,
          ),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => WalletDetailsScreen(
                balance: balance,
                onDepositSuccess: onDepositSuccess,
              ),
            ),
          );
        },
      ),
    );
  }
}
