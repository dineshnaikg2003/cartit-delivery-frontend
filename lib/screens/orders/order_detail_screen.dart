import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/app_colors.dart';
import '../../models/delivery_order_model.dart';
import '../../providers/delivery_order_provider.dart';
import '../../providers/earnings_provider.dart';
import '../../widgets/delivery_confetti_overlay.dart';
import '../../widgets/slide_to_action_button.dart';
import '../map/delivery_map_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final Set<String> _checkedItems = {};
  final TextEditingController _otpController = TextEditingController();
  String? _otpError;
  bool _isBagScanned = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _showOtpBottomSheet(
    BuildContext context,
    DeliveryOrder order,
    DeliveryOrderProvider provider,
    EarningsProvider earningsProvider,
  ) {
    _otpController.clear();
    _otpError = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (bottomCtx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(bottomCtx).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_user,
                            color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer OTP Verification',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDark ? AppColors.darkTitle : AppColors.title,
                              ),
                            ),
                            Text(
                              'Ask 4-digit PIN from ${order.customerName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkSubtitle
                                    : AppColors.subtitle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (order.paymentMethod == 'COD' && !order.isPaid) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.secondary),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.payments, color: AppColors.secondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CASH COLLECTION MANDATORY',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                Text(
                                  'Collect ₹${order.cashToCollect.toStringAsFixed(0)} cash before submitting OTP.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.darkTitle
                                        : AppColors.title,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 12,
                    ),
                    decoration: InputDecoration(
                      hintText: '••••',
                      hintStyle: const TextStyle(letterSpacing: 12),
                      errorText: _otpError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Demo Customer OTP: ${order.customerOtp} (or 1234)',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? AppColors.darkSubtitle
                              : AppColors.subtitle,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _otpController.text = order.customerOtp;
                        },
                        child: const Text(
                          'Auto-Fill',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        bool success = provider.verifyOtpAndCompleteOrder(
                          order.id,
                          _otpController.text,
                        );
                        if (success) {
                          if (order.paymentMethod == 'COD') {
                            earningsProvider
                                .addCodCollection(order.cashToCollect);
                          }
                          earningsProvider.addOrderEarning(
                            earning: order.riderEarning,
                            tip: order.tipAmount,
                          );
                          Navigator.pop(ctx);
                          HapticFeedback.heavyImpact();
                          DeliveryCelebrationDialog.show(
                            context,
                            orderNumber: order.orderNumber,
                            earnedAmount: order.riderEarning,
                            tipAmount: order.tipAmount,
                          );
                        } else {
                          setModalState(() {
                            _otpError =
                                'Invalid OTP. Please ask customer or use ${order.customerOtp}.';
                          });
                        }
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
                      child: const Text(
                        'CONFIRM & COMPLETE DELIVERY',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCancellationDialog(
      BuildContext context, DeliveryOrder order, DeliveryOrderProvider provider) {
    String selectedReason = 'Customer Unreachable / Not Answering';
    final reasons = [
      'Customer Unreachable / Not Answering',
      'Incorrect / Incomplete Delivery Address',
      'Customer Cancelled / Rejected at Doorstep',
      'Severe Rain / Vehicle Breakdown',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.error),
                SizedBox(width: 8),
                Text('Cancel / Return Order', style: TextStyle(fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please select reason to return package to Dark Store:',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                ...reasons.map((r) {
                  final bool isSelected = selectedReason == r;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedReason = r),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : (isDark ? Colors.white10 : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            size: 18,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.subtitle,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              r,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isDark
                                    ? AppColors.darkTitle
                                    : AppColors.title,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Back'),
              ),
              ElevatedButton(
                onPressed: () {
                  provider.cancelOrder(order.id, selectedReason);
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Order marked for return. Please return package to store manager.'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm Return'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<DeliveryOrderProvider>(context);
    final earningsProvider = Provider.of<EarningsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final order = orderProvider.orders.firstWhere(
      (o) => o.id == widget.orderId,
      orElse: () => orderProvider.orders.first,
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        title: Text(
          'Order Details ${order.orderNumber}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTitle : AppColors.title,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined, color: AppColors.primary),
            tooltip: 'Live Map Navigation',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeliveryMapScreen(order: order),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Timeline Progress Card
            _buildStatusTracker(order, isDark),
            const SizedBox(height: 14),

            // Dark Store Bay Pick-up Banner
            _buildDarkStoreBayCard(order, isDark),
            const SizedBox(height: 14),

            // Customer Contact & Action Card
            _buildCustomerCard(order, isDark),
            const SizedBox(height: 14),

            // Delivery Instructions Card
            if (order.deliveryInstructions.isNotEmpty) ...[
              _buildInstructionsCard(order, isDark),
              const SizedBox(height: 14),
            ],

            // Item Checklist Card
            _buildItemChecklist(order, isDark),
            const SizedBox(height: 14),

            // Payment Summary Card
            _buildPaymentSummary(order, isDark),
            const SizedBox(height: 16),

            // Cancel / Return link
            if (order.status != DeliveryOrderStatus.delivered &&
                order.status != DeliveryOrderStatus.cancelled)
              Center(
                child: TextButton.icon(
                  onPressed: () =>
                      _showCancellationDialog(context, order, orderProvider),
                  icon: const Icon(Icons.cancel_outlined,
                      size: 16, color: AppColors.error),
                  label: const Text(
                    'Unable to Deliver? Return to Hub',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),

      // Bottom Bar with Step Action Slider or OTP Trigger
      bottomSheet: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.paymentMethod == 'COD'
                          ? 'Cash to Collect'
                          : 'Payment Status',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkSubtitle
                            : AppColors.subtitle,
                      ),
                    ),
                    Text(
                      order.paymentMethod == 'COD'
                          ? '₹${order.cashToCollect.toStringAsFixed(0)} (COD)'
                          : 'PAID ONLINE',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: order.paymentMethod == 'COD'
                            ? AppColors.secondary
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wallet,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Rider Pay: ₹${order.riderEarning.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (order.status == DeliveryOrderStatus.arrivedAtCustomer)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showOtpBottomSheet(
                    context,
                    order,
                    orderProvider,
                    earningsProvider,
                  ),
                  icon: const Icon(Icons.verified_user, size: 18),
                  label: const Text('VERIFY 4-DIGIT OTP & COMPLETE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              )
            else if (order.status != DeliveryOrderStatus.delivered &&
                order.status != DeliveryOrderStatus.cancelled)
              SlideToActionButton(
                text: order.status.nextActionLabel,
                actionColor: order.status.badgeColor,
                trackColor: order.status.badgeColor.withValues(alpha: 0.12),
                onSlideComplete: () async {
                  await orderProvider.advanceOrderStatus(order.id);
                },
              )
            else
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle,
                        color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'DELIVERY COMPLETED',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkStoreBayCard(DeliveryOrder order, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.qr_code_scanner,
                color: Colors.amber, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Pick-up Bay: ${order.storeBay}',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTitle : AppColors.title,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: _isBagScanned
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _isBagScanned ? 'VERIFIED' : 'PENDING SCAN',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: _isBagScanned
                              ? AppColors.primary
                              : AppColors.subtitle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Bag Barcode: ${order.bagBarcode}',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _isBagScanned ? Icons.check_circle : Icons.qr_code,
              color: _isBagScanned ? AppColors.primary : AppColors.secondary,
            ),
            tooltip: 'Verify Bag QR Scan',
            onPressed: () {
              setState(() => _isBagScanned = !_isBagScanned);
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isBagScanned
                      ? '✅ Bag ${order.bagBarcode} verified successfully!'
                      : 'Bag scan reset.'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTracker(DeliveryOrder order, bool isDark) {
    final steps = [
      DeliveryOrderStatus.assigned,
      DeliveryOrderStatus.arrivedAtStore,
      DeliveryOrderStatus.pickedUp,
      DeliveryOrderStatus.arrivedAtCustomer,
      DeliveryOrderStatus.delivered,
    ];

    int currentIndex = steps.indexOf(order.status);
    if (currentIndex == -1) currentIndex = 0;

    return Container(
      padding: const EdgeInsets.all(14),
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
              Text(
                'Delivery Progress',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTitle : AppColors.title,
                ),
              ),
              Text(
                order.estimatedMins,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(steps.length, (index) {
              bool isDone = index <= currentIndex;
              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppColors.primary
                            : (isDark ? Colors.grey[800] : Colors.grey[300]),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDone ? Icons.check : Icons.circle,
                        size: 12,
                        color: isDone ? Colors.white : Colors.transparent,
                      ),
                    ),
                    if (index < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 3,
                          color: index < currentIndex
                              ? AppColors.primary
                              : (isDark ? Colors.grey[800] : Colors.grey[300]),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(DeliveryOrder order, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.person, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        order.customerName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTitle : AppColors.title,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Masked Call'),
                          content: Text(
                              'Calling ${order.customerName} via private VoIP mask line to protect customer privacy.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                              child: const Text('Call Now'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.phone, size: 13),
                    label: const Text('Call', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: const Icon(Icons.chat,
                        color: AppColors.primary, size: 18),
                    tooltip: 'WhatsApp Notification',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Opening WhatsApp chat with customer...')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Colors.redAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.deliveryAddress,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTitle : AppColors.title,
                      ),
                    ),
                    if (order.landmark != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Landmark: ${order.landmark}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkSubtitle
                              : AppColors.subtitle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard(DeliveryOrder order, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.secondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DELIVERY INSTRUCTION FROM CUSTOMER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order.deliveryInstructions,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTitle : AppColors.title,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemChecklist(DeliveryOrder order, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Text(
                'Items Checklist (${order.items.length} items)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTitle : AppColors.title,
                ),
              ),
              Text(
                '${_checkedItems.length}/${order.items.length} Checked',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          ...order.items.map((item) {
            bool isChecked = _checkedItems.contains(item.id);
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.primary,
              value: isChecked,
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _checkedItems.add(item.id);
                  } else {
                    _checkedItems.remove(item.id);
                  }
                });
              },
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        decoration:
                            isChecked ? TextDecoration.lineThrough : null,
                        color: isDark ? AppColors.darkTitle : AppColors.title,
                      ),
                    ),
                  ),
                  if (item.isCold) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.ac_unit, size: 10, color: Colors.blue),
                          SizedBox(width: 2),
                          Text(
                            'COLD',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Text(
                '${item.variant} • Qty: ${item.quantity}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkSubtitle
                      : AppColors.subtitle,
                ),
              ),
              secondary: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.fastfood,
                    size: 20, color: AppColors.primary),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(DeliveryOrder order, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.darkCardBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTitle : AppColors.title,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Mode',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkSubtitle
                      : AppColors.subtitle,
                ),
              ),
              Text(
                order.paymentMethod,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTitle : AppColors.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Bill Amount',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkSubtitle
                      : AppColors.subtitle,
                ),
              ),
              Text(
                '₹${order.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTitle : AppColors.title,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
