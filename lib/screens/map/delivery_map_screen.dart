import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../app/app_colors.dart';
import '../../models/delivery_order_model.dart';
import '../../providers/delivery_order_provider.dart';
import '../../widgets/slide_to_action_button.dart';
import '../../services/live_tracking_service.dart';

class DeliveryMapScreen extends StatefulWidget {
  final DeliveryOrder order;

  const DeliveryMapScreen({super.key, required this.order});

  @override
  State<DeliveryMapScreen> createState() => _DeliveryMapScreenState();
}

class _DeliveryMapScreenState extends State<DeliveryMapScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
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
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _handleSlideAdvance(DeliveryOrderProvider orderProvider, String orderId) async {
    await orderProvider.advanceOrderStatus(orderId);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _centerOnDriver(LatLng driverPoint) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(driverPoint, 16.0),
    );
  }

  void _fitRouteBounds(LatLng store, LatLng customer, LatLng? driver) {
    if (_mapController == null) return;
    final points = [store, customer];
    if (driver != null) points.add(driver);

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 70),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orderProvider = Provider.of<DeliveryOrderProvider>(context);

    final currentOrder = orderProvider.orders.firstWhere(
      (o) => o.id == widget.order.id,
      orElse: () => widget.order,
    );

    final storePoint = LatLng(currentOrder.storeLat, currentOrder.storeLng);
    final customerPoint = LatLng(currentOrder.customerLat, currentOrder.customerLng);

    // Real driver position from LiveTrackingService only (NO MIDPOINT / FAKE COORDINATES)
    final lastPos = LiveTrackingService().lastValidPosition;
    final LatLng? driverPoint = lastPos != null
        ? LatLng(lastPos.latitude, lastPos.longitude)
        : null;

    final markers = <Marker>{
      // Store Marker
      Marker(
        markerId: const MarkerId('store'),
        position: storePoint,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: currentOrder.storeName,
          snippet: 'Store Location',
        ),
      ),
      // Customer Destination Marker
      Marker(
        markerId: const MarkerId('customer'),
        position: customerPoint,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: currentOrder.customerName,
          snippet: currentOrder.deliveryAddress,
        ),
      ),
    };

    if (driverPoint != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: driverPoint,
          rotation: lastPos?.heading ?? 0.0,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(
            title: 'Your Location (Delivery Partner)',
            snippet: 'Real GPS Position',
          ),
        ),
      );
    }

    final polylinePoints = <LatLng>[storePoint];
    if (driverPoint != null) {
      polylinePoints.add(driverPoint);
    }
    polylinePoints.add(customerPoint);

    final polylines = <Polyline>{
      Polyline(
        polylineId: const PolylineId('delivery_route'),
        points: polylinePoints,
        color: AppColors.primary,
        width: 5,
      ),
    };

    final initialCamera = CameraPosition(
      target: driverPoint ?? customerPoint,
      zoom: 14.5,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            tooltip: 'Fit Route',
            onPressed: () => _fitRouteBounds(storePoint, customerPoint, driverPoint),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: initialCamera,
            markers: markers,
            polylines: polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              _fitRouteBounds(storePoint, customerPoint, driverPoint);
            },
          ),

          // Top Turn-by-Turn Header / GPS Status
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
                    child: Icon(
                      driverPoint != null ? Icons.turn_right_rounded : Icons.gps_off_rounded,
                      color: driverPoint != null ? AppColors.primary : Colors.amber.shade900,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverPoint != null
                              ? (currentOrder.status == DeliveryOrderStatus.assigned
                                  ? 'Head toward ${currentOrder.storeName}'
                                  : 'Follow road navigation route')
                              : 'Waiting for GPS...',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTitle
                                : AppColors.title,
                          ),
                        ),
                        Text(
                          driverPoint != null
                              ? 'ETA ${currentOrder.estimatedMins} • ${currentOrder.distanceCustomerKm} km remaining'
                              : 'Acquiring real-time device location stream...',
                          style: TextStyle(
                            fontSize: 11,
                            color: driverPoint != null ? AppColors.primary : Colors.amber.shade900,
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

          // Center on Driver Floating Action Button
          if (driverPoint != null)
            Positioned(
              right: 16,
              bottom: 250,
              child: FloatingActionButton.small(
                heroTag: 'center_driver',
                backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
                foregroundColor: AppColors.primary,
                onPressed: () => _centerOnDriver(driverPoint),
                child: const Icon(Icons.my_location),
              ),
            ),

          // Bottom Route Details Floating Card
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
                          label: const Text('Google Maps'),
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
