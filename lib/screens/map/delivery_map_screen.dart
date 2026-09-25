import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../app/app_colors.dart';
import '../../models/delivery_order_model.dart';
import '../../providers/delivery_order_provider.dart';
import '../../widgets/slide_to_action_button.dart';

class DeliveryMapScreen extends StatefulWidget {
  final DeliveryOrder order;

  const DeliveryMapScreen({super.key, required this.order});

  @override
  State<DeliveryMapScreen> createState() => _DeliveryMapScreenState();
}

class _DeliveryMapScreenState extends State<DeliveryMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _handleSlideAdvance(DeliveryOrderProvider orderProvider, String orderId) async {
    await orderProvider.advanceOrderStatus(orderId);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orderProvider = Provider.of<DeliveryOrderProvider>(context);

    final currentOrder = orderProvider.orders.firstWhere(
      (o) => o.id == widget.order.id,
      orElse: () => widget.order,
    );

    // LatLng points
    final storePoint = LatLng(currentOrder.storeLat, currentOrder.storeLng);
    final customerPoint =
        LatLng(currentOrder.customerLat, currentOrder.customerLng);

    // Delivery partner location
    final partnerPoint = LatLng(
      (currentOrder.storeLat + currentOrder.customerLat) / 2,
      (currentOrder.storeLng + currentOrder.customerLng) / 2,
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Delivery Route',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTitle : AppColors.title,
              ),
            ),
            Text(
              'Order ${currentOrder.orderNumber} • ${currentOrder.estimatedMins}',
              style: const TextStyle(fontSize: 11, color: AppColors.primary),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // FlutterMap rendering OpenStreetMap
          FlutterMap(
            options: MapOptions(
              initialCenter: partnerPoint,
              initialZoom: 14.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.cartit.delivery',
              ),

              // Polyline Route Path
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [storePoint, partnerPoint, customerPoint],
                    strokeWidth: 5.0,
                    color: AppColors.primary,
                  ),
                ],
              ),

              // Map Markers
              MarkerLayer(
                markers: [
                  // Store Marker
                  Marker(
                    point: storePoint,
                    width: 44,
                    height: 44,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 6),
                        ],
                      ),
                      child:
                          const Icon(Icons.store, color: Colors.black, size: 24),
                    ),
                  ),

                  // Animated Delivery Partner Marker with Radar Pulse
                  Marker(
                    point: partnerPoint,
                    width: 64,
                    height: 64,
                    child: AnimatedBuilder(
                      animation: _radarController,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 32 + (32 * _radarController.value),
                              height: 32 + (32 * _radarController.value),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withValues(
                                  alpha: (1.0 - _radarController.value) * 0.4,
                                ),
                              ),
                            ),
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.two_wheeler,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Customer Destination Marker
                  Marker(
                    point: customerPoint,
                    width: 44,
                    height: 44,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 6),
                        ],
                      ),
                      child: const Icon(Icons.location_on,
                          color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Top Navigation Turn-by-Turn Maneuver Header
          Positioned(
            left: 14,
            right: 14,
            top: 14,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.turn_right_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentOrder.status == DeliveryOrderStatus.assigned
                              ? 'Head toward ${currentOrder.storeName}'
                              : 'Turn right in 150m onto 12th Main Rd',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTitle
                                : AppColors.title,
                          ),
                        ),
                        Text(
                          'ETA ${currentOrder.estimatedMins} • ${currentOrder.distanceCustomerKm} km remaining',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Route Details Floating Drawer Card
          Positioned(
            left: 14,
            right: 14,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.border,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentOrder.customerName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.darkTitle
                                  : AppColors.title,
                            ),
                          ),
                          Text(
                            currentOrder.deliveryAddress,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkSubtitle
                                  : AppColors.subtitle,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          currentOrder.estimatedMins,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Quick Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Launching external Google Maps Navigation...'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.navigation, size: 16),
                          label: const Text('Maps GPS'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.phone, color: AppColors.primary),
                        tooltip: 'Call Customer',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Calling ${currentOrder.customerName}...'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  if (currentOrder.status != DeliveryOrderStatus.delivered &&
                      currentOrder.status != DeliveryOrderStatus.cancelled) ...[
                    const SizedBox(height: 10),
                    SlideToActionButton(
                      text: currentOrder.status.nextActionLabel,
                      actionColor: currentOrder.status.badgeColor,
                      trackColor: currentOrder.status.badgeColor
                          .withValues(alpha: 0.12),
                      onSlideComplete: () =>
                          _handleSlideAdvance(orderProvider, currentOrder.id),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
