import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/duty_provider.dart';
import '../../providers/delivery_order_provider.dart';
import '../../providers/earnings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/location_security_guard.dart';
import '../../widgets/incoming_order_dialog.dart';
import '../orders/allocated_orders_screen.dart';
import '../earnings/earnings_screen.dart';
import '../profile/delivery_profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocationSecurityGuard.startSecurityMonitoring(
        context,
        onViolationDetected: (reason) {
          debugPrint('LOCATION SECURITY ALERT: $reason');
        },
      );
    });
  }

  @override
  void dispose() {
    LocationSecurityGuard.stopMonitoring();
    super.dispose();
  }

  final List<Widget> _pages = const [
    AllocatedOrdersScreen(),
    EarningsScreen(),
    DeliveryProfileScreen(),
  ];

  Future<void> _simulateIncomingOrder() async {
    final orderProvider =
        Provider.of<DeliveryOrderProvider>(context, listen: false);
    final dutyProvider = Provider.of<DutyProvider>(context, listen: false);

    if (!dutyProvider.isOnDuty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please go ON DUTY to receive new order allocations.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final newOrder = orderProvider.generateSimulatedOrder();
    final accepted = await IncomingOrderDialog.show(context, order: newOrder);

    if (!mounted) return;
    if (accepted == true) {
      orderProvider.addIncomingOrder(newOrder);
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Order ${newOrder.orderNumber} Accepted!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dutyProvider = Provider.of<DutyProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final orderProvider = Provider.of<DeliveryOrderProvider>(context);
    final earningsProvider = Provider.of<EarningsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final partnerName =
        authProvider.currentUser?.name ?? dutyProvider.partnerName;
    final partnerId =
        authProvider.currentUser?.id ?? dutyProvider.partnerId;
    final hubName =
        authProvider.currentUser?.hubName ?? dutyProvider.hubName;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(126),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkHeaderBg : AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                children: [
                  // Row 1: Partner Info & Duty Switch & Simulator trigger (Responsive)
                  Row(
                    children: [
                      // Partner Avatar & Info
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 17,
                              backgroundColor: AppColors.primaryLight,
                              backgroundImage: dutyProvider.profilePicPath != null
                                  ? FileImage(File(dutyProvider.profilePicPath!))
                                      as ImageProvider
                                  : null,
                              child: dutyProvider.profilePicPath == null
                                  ? const Icon(
                                      Icons.delivery_dining,
                                      color: AppColors.primary,
                                      size: 20,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          partnerName,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? AppColors.darkTitle
                                                : AppColors.title,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          partnerId,
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    hubName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark
                                          ? AppColors.darkSubtitle
                                          : AppColors.subtitle,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Actions: Simulator, Theme Toggle, Duty Switch
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Simulated Incoming Dispatch Button
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 28, minHeight: 28),
                            icon: const Icon(Icons.add_alert_rounded,
                                color: AppColors.secondary, size: 18),
                            tooltip: 'Simulate Incoming Order',
                            onPressed: _simulateIncomingOrder,
                          ),
                          // Theme toggle
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 28, minHeight: 28),
                            icon: Icon(
                              isDark ? Icons.light_mode : Icons.dark_mode,
                              color: isDark ? Colors.amber : AppColors.title,
                              size: 18,
                            ),
                            tooltip: isDark
                                ? 'Switch to Light Mode'
                                : 'Switch to Dark Mode',
                            onPressed: () => themeProvider.toggleTheme(context),
                          ),
                          const SizedBox(width: 4),
                          // Duty Switch Toggle
                          GestureDetector(
                            onTap: () {
                              dutyProvider.toggleDuty();
                              HapticFeedback.mediumImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    dutyProvider.isOnDuty
                                        ? 'You are now ON DUTY. Ready to receive order allocations.'
                                        : 'You are now OFF DUTY.',
                                  ),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: dutyProvider.isOnDuty
                                      ? AppColors.primary
                                      : AppColors.error,
                                ),
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: dutyProvider.isOnDuty
                                    ? AppColors.primary
                                    : (isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[300]),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    dutyProvider.isOnDuty
                                        ? 'ON DUTY'
                                        : 'OFF DUTY',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 2: Live Metrics Bar (Shift Timer, Today Payout, COD Cash)
                  Row(
                    children: [
                      Expanded(
                        child: _MetricBadge(
                          icon: Icons.timer,
                          label: 'Duty Shift',
                          value: dutyProvider.formattedShiftTime,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _MetricBadge(
                          icon: Icons.payments,
                          label: "Today's Earned",
                          value:
                              '₹${earningsProvider.todayTotalPayout.toStringAsFixed(0)}',
                          isDark: isDark,
                          highlightColor: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _MetricBadge(
                          icon: Icons.account_balance_wallet,
                          label: 'Cash in Hand',
                          value:
                              '₹${earningsProvider.cashInHand.toStringAsFixed(0)}',
                          isDark: isDark,
                          highlightColor: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkCardBorder : AppColors.border,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor:
              isDark ? AppColors.darkSubtitle : AppColors.subtitle,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: [
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.assignment),
                  if (orderProvider.activeOrders.isNotEmpty)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${orderProvider.activeOrders.length}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Allocated Orders',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet),
              label: 'Earnings',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final Color? highlightColor;

  const _MetricBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 11,
                color: highlightColor ??
                    (isDark ? AppColors.darkSubtitle : AppColors.subtitle),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 8.5,
                    color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: highlightColor ??
                  (isDark ? AppColors.darkTitle : AppColors.title),
            ),
          ),
        ],
      ),
    );
  }
}
