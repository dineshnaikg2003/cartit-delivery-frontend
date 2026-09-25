import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_colors.dart';
import '../../providers/earnings_provider.dart';
import '../../widgets/earnings_chart_widget.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  void _showWithdrawalDialog(BuildContext context, EarningsProvider provider) {
    final TextEditingController amountController = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.account_balance, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Instant Payout Withdrawal',
                    style: TextStyle(fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Wallet Balance: ₹${provider.walletBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Withdrawal Amount (₹)',
                    errorText: error,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Transfers instantly to linked UPI: rahul.sharma@okaxis',
                  style: TextStyle(fontSize: 11, color: AppColors.subtitle),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text) ?? 0.0;
                  if (amount <= 0 || amount > provider.walletBalance) {
                    setDialogState(() {
                      error = 'Please enter amount up to ₹${provider.walletBalance.toStringAsFixed(0)}';
                    });
                    return;
                  }
                  provider.withdrawFunds(amount);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '🎉 ₹${amount.toStringAsFixed(0)} withdrawn successfully to your bank!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Transfer Now'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDepositCashDialog(BuildContext context, EarningsProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.storefront, color: AppColors.secondary),
            SizedBox(width: 8),
            Text('Deposit Cash in Hand', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cash Held: ₹${provider.cashInHand.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Deposit cash collection at your Dark Store Hub Cashier Desk or scan Dark Store UPI QR Code.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.receipt_long, size: 18, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    'Cashier Receipt Slip #CSH-8942',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.depositCashInHand();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Cash deposit confirmed! Cash in hand reset to ₹0.'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Confirm Cash Deposit',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final earningsProvider = Provider.of<EarningsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's Total Payout Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0F261B), const Color(0xFF141F1A)]
                    : [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "TODAY'S TOTAL PAYOUT",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${earningsProvider.todayCompletedCount} DELIVERIES',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${earningsProvider.todayTotalPayout.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 14),

                // Payout Breakdown Items
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _PayoutPill(
                        label: 'Base Pay',
                        amount: earningsProvider.todayBasePay),
                    _PayoutPill(
                        label: 'Distance Pay',
                        amount: earningsProvider.todayDistanceBonus),
                    _PayoutPill(
                        label: 'Peak Surge',
                        amount: earningsProvider.todaySurge),
                    _PayoutPill(
                        label: 'Tips (100%)',
                        amount: earningsProvider.todayTips),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Interactive Weekly Performance Chart
          EarningsChartWidget(
            weeklyData: earningsProvider.weeklyBarData,
            maxGoal: 1200.0,
          ),
          const SizedBox(height: 16),

          // Daily Milestone Bonus Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.military_tech,
                            color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Daily Milestone Target',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? AppColors.darkTitle : AppColors.title,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+₹${earningsProvider.nextMilestoneBonus.toStringAsFixed(0)} BONUS',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete ${earningsProvider.nextMilestoneOrders - earningsProvider.todayCompletedCount} more orders today to unlock ₹${earningsProvider.nextMilestoneBonus.toStringAsFixed(0)} extra bonus!',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                  ),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: earningsProvider.milestoneProgress,
                  backgroundColor:
                      isDark ? Colors.grey[800] : Colors.grey[200],
                  color: AppColors.primary,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Wallet Balance & Instant Withdrawal Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Withdrawable Wallet Balance',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkSubtitle
                            : AppColors.subtitle,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${earningsProvider.walletBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      _showWithdrawalDialog(context, earningsProvider),
                  icon: const Icon(Icons.account_balance, size: 16),
                  label: const Text('Withdraw',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Cash in Hand Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cash Held (COD Collected)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkSubtitle
                            : AppColors.subtitle,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${earningsProvider.cashInHand.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () =>
                      _showDepositCashDialog(context, earningsProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Deposit Cash',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Recent Days History List
          Text(
            'Payout History',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTitle : AppColors.title,
            ),
          ),
          const SizedBox(height: 10),
          ...earningsProvider.recentDays.map((day) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark
                        ? AppColors.darkCardBorder
                        : AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day.date,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? AppColors.darkTitle : AppColors.title,
                        ),
                      ),
                      Text(
                        '${day.completedOrders} orders completed',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkSubtitle
                              : AppColors.subtitle,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₹${day.totalPayout.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PayoutPill extends StatelessWidget {
  final String label;
  final double amount;

  const _PayoutPill({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white70),
        ),
        const SizedBox(height: 2),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }
}
