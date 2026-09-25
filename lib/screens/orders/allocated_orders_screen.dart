import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_colors.dart';
import '../../models/delivery_order_model.dart';
import '../../providers/delivery_order_provider.dart';
import '../../widgets/slide_to_action_button.dart';
import 'order_detail_screen.dart';
import '../map/delivery_map_screen.dart';

class AllocatedOrdersScreen extends StatefulWidget {
  const AllocatedOrdersScreen({super.key});

  @override
  State<AllocatedOrdersScreen> createState() => _AllocatedOrdersScreenState();
}

class _AllocatedOrdersScreenState extends State<AllocatedOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<DeliveryOrderProvider>(context, listen: false).syncLiveTrackingState();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<DeliveryOrderProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Tab Header
        Container(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor:
                isDark ? AppColors.darkSubtitle : AppColors.subtitle,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Allocated Active'),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${orderProvider.activeOrders.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Delivered Today'),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${orderProvider.completedOrders.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTitle : AppColors.title,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Tab Content
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => orderProvider.fetchAllocatedOrders(),
            color: AppColors.primary,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(
                    orderProvider.activeOrders, orderProvider, isDark, false),
                _buildOrdersList(orderProvider.completedOrders, orderProvider,
                    isDark, true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersList(
    List<DeliveryOrder> ordersList,
    DeliveryOrderProvider provider,
    bool isDark,
    bool isCompletedTab,
  ) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (ordersList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompletedTab ? Icons.task_alt : Icons.moped,
              size: 64,
              color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
            ),
            const SizedBox(height: 16),
            Text(
              isCompletedTab
                  ? 'No deliveries completed yet today'
                  : 'No active orders allocated right now',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCompletedTab
                  ? 'Your completed orders will appear here'
                  : 'Stay on duty! Tap bell icon above to test incoming orders.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: ordersList.length,
      itemBuilder: (context, index) {
        final order = ordersList[index];
        return _AllocatedOrderCard(
          order: order,
          isDark: isDark,
          onAdvanceStatus: () => provider.advanceOrderStatus(order.id),
        );
      },
    );
  }
}

class _AllocatedOrderCard extends StatelessWidget {
  final DeliveryOrder order;
  final bool isDark;
  final VoidCallback onAdvanceStatus;

  const _AllocatedOrderCard({
    required this.order,
    required this.isDark,
    required this.onAdvanceStatus,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = order.status.badgeColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.border,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Order Number, Express tag, Status Chip (Fully Responsive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.grey[50],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkCardBorder : AppColors.border,
                ),
              ),
            ),
            child: Row(
              children: [
                // Order Number & Tag
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          order.orderNumber,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? AppColors.darkTitle : AppColors.title,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt, size: 11, color: Colors.black),
                            SizedBox(width: 2),
                            Text(
                              '10 MIN',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    order.status.label,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body: Dark Store Bay & Addresses
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Store Location Box
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.store, color: Colors.amber, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  order.storeName,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
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
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  order.storeBay,
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            order.storeAddress,
                            style: TextStyle(
                              fontSize: 10.5,
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
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: order.distanceStoreKm < 1.0
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : (isDark ? Colors.white10 : Colors.grey[200]),
                        borderRadius: BorderRadius.circular(5),
                        border: order.distanceStoreKm < 1.0
                            ? Border.all(color: AppColors.primary, width: 0.8)
                            : null,
                      ),
                      child: Text(
                        '${order.distanceStoreKm} km away',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: order.distanceStoreKm < 1.0
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.darkSubtitle
                                  : AppColors.subtitle),
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: SizedBox(
                    height: 14,
                    child: VerticalDivider(thickness: 1.5, color: Colors.grey),
                  ),
                ),
                // Customer Delivery Location Box
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on,
                          color: AppColors.primary, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  order.customerName,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
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
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  order.addressType,
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            order.deliveryAddress,
                            style: TextStyle(
                              fontSize: 10.5,
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
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${order.distanceCustomerKm} km delivery',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkSubtitle
                              : AppColors.subtitle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Payment & Item Count Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 13,
                          color: isDark
                              ? AppColors.darkSubtitle
                              : AppColors.subtitle,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${order.totalItemCount} Items (₹${order.totalAmount.toStringAsFixed(0)})',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? AppColors.darkTitle : AppColors.title,
                          ),
                        ),
                      ],
                    ),

                    // COD vs Paid pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: order.paymentMethod == 'COD'
                            ? AppColors.secondary.withValues(alpha: 0.15)
                            : AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: order.paymentMethod == 'COD'
                              ? AppColors.secondary
                              : AppColors.primary,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            order.paymentMethod == 'COD'
                                ? Icons.payments_outlined
                                : Icons.check_circle_outline,
                            size: 11,
                            color: order.paymentMethod == 'COD'
                                ? AppColors.secondary
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            order.paymentMethod == 'COD'
                                ? 'COLLECT COD ₹${order.cashToCollect.toStringAsFixed(0)}'
                                : 'PREPAID ONLINE',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: order.paymentMethod == 'COD'
                                  ? AppColors.secondary
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Slide-to-Action Bar for Active Orders
          if (order.status != DeliveryOrderStatus.delivered &&
              order.status != DeliveryOrderStatus.cancelled) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: SlideToActionButton(
                text: order.status.nextActionLabel,
                actionColor: statusColor,
                trackColor: statusColor.withValues(alpha: 0.12),
                onSlideComplete: () async {
                  onAdvanceStatus();
                },
              ),
            ),
            const SizedBox(height: 4),
          ],

          // Footer Action Buttons: Live Map & Details
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.grey[50],
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkCardBorder : AppColors.border,
                ),
              ),
            ),
            child: Row(
              children: [
                // Live Map Route Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DeliveryMapScreen(order: order),
                        ),
                      );
                    },
                    icon: const Icon(Icons.map_outlined, size: 15),
                    label:
                        const Text('Live Map', style: TextStyle(fontSize: 11.5)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Full Order Detail Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(orderId: order.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long, size: 15),
                    label:
                        const Text('Details', style: TextStyle(fontSize: 11.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.darkCardBorder
                          : Colors.grey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
