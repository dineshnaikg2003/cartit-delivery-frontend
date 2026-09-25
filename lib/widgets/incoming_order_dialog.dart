import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/app_colors.dart';
import '../models/delivery_order_model.dart';

class IncomingOrderDialog extends StatefulWidget {
  final DeliveryOrder order;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const IncomingOrderDialog({
    super.key,
    required this.order,
    required this.onAccept,
    required this.onDecline,
  });

  static Future<bool?> show(
    BuildContext context, {
    required DeliveryOrder order,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => IncomingOrderDialog(
        order: order,
        onAccept: () => Navigator.of(ctx).pop(true),
        onDecline: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  @override
  State<IncomingOrderDialog> createState() => _IncomingOrderDialogState();
}

class _IncomingOrderDialogState extends State<IncomingOrderDialog> {
  int _secondsRemaining = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    HapticFeedback.vibrate();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        widget.onDecline();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double payoutEstimate = 35.0 + (widget.order.distanceCustomerKm * 15.0);

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Header with Countdown Timer Circle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bolt, color: AppColors.secondary, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'NEW ORDER ALLOCATION',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Countdown circle
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 38,
                        height: 38,
                        child: CircularProgressIndicator(
                          value: _secondsRemaining / 30.0,
                          backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
                          color: _secondsRemaining <= 10
                              ? AppColors.error
                              : AppColors.secondary,
                          strokeWidth: 3.5,
                        ),
                      ),
                      Text(
                        '$_secondsRemaining',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: _secondsRemaining <= 10
                              ? AppColors.error
                              : (isDark ? AppColors.darkTitle : AppColors.title),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Estimated Payout Banner
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0F261B), const Color(0xFF141F1A)]
                        : [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ESTIMATED EARNING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${payoutEstimate.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.order.estimatedMins,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Dark Store and Customer Distance Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.storefront,
                            size: 16, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.order.storeName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.darkTitle
                                  : AppColors.title,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${widget.order.distanceStoreKm} km',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.order.deliveryAddress,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkSubtitle
                                  : AppColors.subtitle,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${widget.order.distanceCustomerKm} km',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkSubtitle
                                : AppColors.subtitle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons: Decline & Accept
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _timer?.cancel();
                        widget.onDecline();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? AppColors.darkSubtitle
                            : AppColors.subtitle,
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkCardBorder
                              : AppColors.border,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'DECLINE',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        _timer?.cancel();
                        HapticFeedback.mediumImpact();
                        widget.onAccept();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'ACCEPT ORDER',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
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
        ),
      ),
    );
  }
}
