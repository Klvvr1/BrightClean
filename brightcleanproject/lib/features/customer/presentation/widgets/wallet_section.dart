import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class WalletSection extends StatelessWidget {
  final String balance;

  const WalletSection({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.account_balance_wallet, color: AppColors.primary),
        title: const Text('المحفظة / النقاط'),
        trailing: Text(
          balance,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.success,
            fontSize: 16,
          ),
        ),
        onTap: () {
          // Navigate to wallet
        },
      ),
    );
  }
}
