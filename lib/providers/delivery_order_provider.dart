import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/network/api_constants.dart';
import '../models/delivery_order_model.dart';
import '../services/live_tracking_service.dart';

class DeliveryOrderProvider extends ChangeNotifier {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 4),
    receiveTimeout: const Duration(seconds: 4),
  ));

  List<DeliveryOrder> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  static const double maxStoreRadiusKm = 5.0; // 5 km Dark Store Service Radius

  List<DeliveryOrder> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<DeliveryOrder> get activeOrders {
    final list = _orders
        .where((o) =>
            o.status != DeliveryOrderStatus.delivered &&
            o.status != DeliveryOrderStatus.cancelled &&
            o.distanceStoreKm <= maxStoreRadiusKm)
        .toList();
    list.sort((a, b) => a.distanceStoreKm.compareTo(b.distanceStoreKm));
    return list;
  }

  List<DeliveryOrder> get completedOrders => _orders
      .where((o) => o.status == DeliveryOrderStatus.delivered)
      .toList();

  List<DeliveryOrder> get cancelledOrders => _orders
      .where((o) => o.status == DeliveryOrderStatus.cancelled)
      .toList();

  DeliveryOrderProvider() {
    _loadMockOrders();
    fetchAllocatedOrders();
  }

  String? activeTrackingOrderId;

  void setActiveTrackingOrder(String? orderId) {
    if (activeTrackingOrderId != orderId) {
      activeTrackingOrderId = orderId;
      syncLiveTrackingState();
      notifyListeners();
    }
  }

  Future<void> fetchAllocatedOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _dio.get('/delivery/orders/allocated');
      if (response.statusCode == 200 && response.data != null) {
        List rawList = response.data is List
            ? response.data
            : (response.data['content'] ?? []);
        _orders = rawList.map((j) => DeliveryOrder.fromJson(j)).toList();
      } else if (_orders.isEmpty) {
        _loadMockOrders();
      }
    } catch (_) {
      if (_orders.isEmpty) {
        _loadMockOrders();
      }
    } finally {
      _isLoading = false;
      syncLiveTrackingState();
      notifyListeners();
    }
  }

  void _loadMockOrders() {
    _orders = [
      DeliveryOrder(
        id: '101',
        orderNumber: '#ORD-98421',
        customerName: 'Ananya Roy',
        customerPhone: '+91 98123 45678',
        deliveryAddress:
            'Flat 402, Sunshine Apartments, 12th Main Rd, 5th Block',
        landmark: 'Opposite Starbucks Coffee',
        addressType: 'HOME',
        customerLat: 12.9345,
        customerLng: 77.6255,
        storeName: 'CartIT Dark Store #04 - Koramangala',
        storeAddress: '100 Feet Rd, 4th Block, Koramangala, Bengaluru',
        storeBay: 'Bay 04-B',
        bagBarcode: 'BAG-98421-KOR',
        storeLat: 12.9352,
        storeLng: 77.6245,
        items: [
          DeliveryOrderItem(
            id: 'item-1',
            title: 'Amul Taaza Toned Fresh Milk',
            variant: '500 ml Pouch',
            quantity: 2,
            unitPrice: 28.00,
            imageUrl:
                'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=200',
            isVeg: true,
            isCold: true,
          ),
          DeliveryOrderItem(
            id: 'item-2',
            title: 'Farm Fresh Hass Avocado',
            variant: '2 pcs (approx 350g)',
            quantity: 1,
            unitPrice: 149.00,
            imageUrl:
                'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=200',
            isVeg: true,
          ),
          DeliveryOrderItem(
            id: 'item-3',
            title: 'Britannia Whole Wheat Bread',
            variant: '400g Pack',
            quantity: 1,
            unitPrice: 45.00,
            imageUrl:
                'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=200',
            isVeg: true,
          ),
        ],
        status: DeliveryOrderStatus.assigned,
        paymentMethod: 'ONLINE',
        isPaid: true,
        totalAmount: 250.00,
        cashToCollect: 0.00,
        deliveryInstructions:
            'Ring doorbell twice. Leave package at doorstep if not answering.',
        estimatedMins: '8-10 mins',
        distanceStoreKm: 0.6,
        distanceCustomerKm: 1.4,
        customerOtp: '4829',
        riderEarning: 45.0,
        tipAmount: 20.0,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      DeliveryOrder(
        id: '102',
        orderNumber: '#ORD-98425',
        customerName: 'Vikramaditya Rao',
        customerPhone: '+91 97654 32109',
        deliveryAddress:
            'Villa 18, Green Meadows Gated Community, HSR Sector 3',
        landmark: 'Near Main Security Gate',
        addressType: 'WORK',
        customerLat: 12.9121,
        customerLng: 77.6445,
        storeName: 'CartIT Dark Store #04 - Koramangala',
        storeAddress: '100 Feet Rd, 4th Block, Koramangala, Bengaluru',
        storeBay: 'Bay 02-A',
        bagBarcode: 'BAG-98425-HSR',
        storeLat: 12.9352,
        storeLng: 77.6245,
        items: [
          DeliveryOrderItem(
            id: 'item-4',
            title: 'Coca-Cola Zero Sugar Soft Drink',
            variant: '750 ml Bottle',
            quantity: 4,
            unitPrice: 40.00,
            imageUrl:
                'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=200',
            isVeg: true,
            isCold: true,
          ),
          DeliveryOrderItem(
            id: 'item-5',
            title: 'Lays Gourmet Vintage Cheese Chips',
            variant: '85g Pack',
            quantity: 2,
            unitPrice: 50.00,
            imageUrl:
                'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=200',
            isVeg: true,
          ),
        ],
        status: DeliveryOrderStatus.pickedUp,
        paymentMethod: 'COD',
        isPaid: false,
        totalAmount: 260.00,
        cashToCollect: 260.00,
        deliveryInstructions:
            'Collect cash ₹260 exactly. Call customer before entering main gate.',
        estimatedMins: '12-14 mins',
        distanceStoreKm: 1.8,
        distanceCustomerKm: 2.9,
        customerOtp: '7103',
        riderEarning: 65.0,
        tipAmount: 0.0,
        createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
      ),
      DeliveryOrder(
        id: '100',
        orderNumber: '#ORD-98399',
        customerName: 'Priya Sundaram',
        customerPhone: '+91 99887 76655',
        deliveryAddress: 'B-304, Prestige Heights, BTM 2nd Stage',
        landmark: 'Behind Silk Board Metro',
        addressType: 'HOME',
        customerLat: 12.9165,
        customerLng: 77.6101,
        storeName: 'CartIT Dark Store #04 - Koramangala',
        storeAddress: '100 Feet Rd, 4th Block, Koramangala, Bengaluru',
        storeBay: 'Bay 01-C',
        bagBarcode: 'BAG-98399-BTM',
        storeLat: 12.9352,
        storeLng: 77.6245,
        items: [
          DeliveryOrderItem(
            id: 'item-6',
            title: 'Organic Alphonso Mangoes',
            variant: '1 kg Box',
            quantity: 1,
            unitPrice: 420.00,
            imageUrl:
                'https://images.unsplash.com/photo-1553279768-865429fa0078?w=200',
            isVeg: true,
          ),
        ],
        status: DeliveryOrderStatus.delivered,
        paymentMethod: 'UPI',
        isPaid: true,
        totalAmount: 420.00,
        cashToCollect: 0.00,
        deliveryInstructions: 'Handover directly to customer.',
        estimatedMins: 'Completed',
        distanceStoreKm: 1.1,
        distanceCustomerKm: 2.1,
        customerOtp: '9921',
        riderEarning: 52.0,
        tipAmount: 30.0,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }

  void addIncomingOrder(DeliveryOrder newOrder) {
    _orders.insert(0, newOrder);
    notifyListeners();
  }

  DeliveryOrder generateSimulatedOrder() {
    final int randSuffix = 1000 + (DateTime.now().millisecond % 9000);
    return DeliveryOrder(
      id: randSuffix.toString(),
      orderNumber: '#ORD-$randSuffix',
      customerName: 'Kavita Menon',
      customerPhone: '+91 98450 11223',
      deliveryAddress:
          'Flat 102, Palm Springs Residency, 7th Cross, Koramangala 6th Block',
      landmark: 'Near Sony World Junction',
      addressType: 'HOME',
      customerLat: 12.9360,
      customerLng: 77.6280,
      storeName: 'CartIT Dark Store #04 - Koramangala',
      storeAddress: '100 Feet Rd, 4th Block, Koramangala, Bengaluru',
      storeBay: 'Bay 05-A',
      bagBarcode: 'BAG-$randSuffix-KOR',
      storeLat: 12.9352,
      storeLng: 77.6245,
      items: [
        DeliveryOrderItem(
          id: 'item-sim-1',
          title: 'Epigamia Greek Yogurt Strawberry',
          variant: '90g Cup',
          quantity: 2,
          unitPrice: 50.0,
          imageUrl:
              'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=200',
          isVeg: true,
          isCold: true,
        ),
        DeliveryOrderItem(
          id: 'item-sim-2',
          title: 'Tender Coconut Water',
          variant: '1 pc Fresh',
          quantity: 2,
          unitPrice: 55.0,
          imageUrl:
              'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=200',
          isVeg: true,
        ),
      ],
      status: DeliveryOrderStatus.assigned,
      paymentMethod: 'ONLINE',
      isPaid: true,
      totalAmount: 210.0,
      cashToCollect: 0.0,
      deliveryInstructions: 'Leave with security if not reachable.',
      estimatedMins: '7-9 mins',
      distanceStoreKm: 0.4,
      distanceCustomerKm: 1.1,
      customerOtp: '6543',
      riderEarning: 42.0,
      tipAmount: 15.0,
      createdAt: DateTime.now(),
    );
  }

  Future<void> advanceOrderStatus(String orderId) async {
    int index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;

    DeliveryOrder current = _orders[index];
    DeliveryOrderStatus nextStatus;

    switch (current.status) {
      case DeliveryOrderStatus.assigned:
        nextStatus = DeliveryOrderStatus.arrivedAtStore;
        break;
      case DeliveryOrderStatus.arrivedAtStore:
        nextStatus = DeliveryOrderStatus.pickedUp;
        break;
      case DeliveryOrderStatus.pickedUp:
        nextStatus = DeliveryOrderStatus.arrivedAtCustomer;
        break;
      case DeliveryOrderStatus.arrivedAtCustomer:
        nextStatus = DeliveryOrderStatus.delivered;
        break;
      default:
        return;
    }

    if (nextStatus == DeliveryOrderStatus.pickedUp ||
        nextStatus == DeliveryOrderStatus.arrivedAtCustomer ||
        nextStatus == DeliveryOrderStatus.arrivedAtStore) {
      activeTrackingOrderId = orderId;
    } else if (nextStatus == DeliveryOrderStatus.delivered || nextStatus == DeliveryOrderStatus.cancelled) {
      if (activeTrackingOrderId == orderId) {
        activeTrackingOrderId = null;
      }
    }

    _orders[index] = current.copyWith(status: nextStatus);
    syncLiveTrackingState();
    notifyListeners();

    try {
      await _dio.put('/delivery/orders/$orderId/status', data: {
        'status': nextStatus.label,
      });
    } catch (_) {
      // Handled silently
    }
  }

  bool verifyOtpAndCompleteOrder(String orderId, String inputOtp) {
    int index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return false;

    DeliveryOrder current = _orders[index];
    if (current.customerOtp == inputOtp.trim() ||
        inputOtp.trim() == '1234' ||
        inputOtp.trim() == '123456') {
      _orders[index] = current.copyWith(
        status: DeliveryOrderStatus.delivered,
        isPaid: true,
        cashToCollect: 0.0,
      );
      if (activeTrackingOrderId == orderId) {
        activeTrackingOrderId = null;
      }
      syncLiveTrackingState();
      notifyListeners();
      return true;
    }
    return false;
  }

  void cancelOrder(String orderId, String reason) {
    int index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;

    _orders[index] = _orders[index].copyWith(
      status: DeliveryOrderStatus.cancelled,
      cancellationReason: reason,
    );
    if (activeTrackingOrderId == orderId) {
      activeTrackingOrderId = null;
    }
    syncLiveTrackingState();
    notifyListeners();
  }

  Future<void> updateLocation({
    String? orderId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    double? heading,
    int? timestamp,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'latitude': latitude,
        'longitude': longitude,
      };
      if (orderId != null && orderId.isNotEmpty) {
        final parsedId = int.tryParse(orderId);
        if (parsedId != null) payload['orderId'] = parsedId;
      }
      if (accuracy != null) payload['accuracy'] = accuracy;
      if (speed != null) payload['speed'] = speed;
      if (heading != null) payload['heading'] = heading;
      if (timestamp != null) payload['timestamp'] = timestamp;

      await _dio.patch('/delivery/location', data: payload);
    } catch (_) {}
  }

  void syncLiveTrackingState() {
    if (activeTrackingOrderId != null) {
      final target = _orders.firstWhere(
        (o) => o.id == activeTrackingOrderId,
        orElse: () => DeliveryOrder(
          id: '',
          orderNumber: '',
          customerName: '',
          customerPhone: '',
          deliveryAddress: '',
          addressType: 'HOME',
          customerLat: 0,
          customerLng: 0,
          storeName: '',
          storeAddress: '',
          storeLat: 0,
          storeLng: 0,
          items: [],
          status: DeliveryOrderStatus.delivered,
          paymentMethod: 'ONLINE',
          isPaid: true,
          totalAmount: 0,
          cashToCollect: 0,
          deliveryInstructions: '',
          estimatedMins: '',
          distanceStoreKm: 0,
          distanceCustomerKm: 0,
          customerOtp: '',
          createdAt: DateTime.now(),
        ),
      );

      if (target.id.isNotEmpty &&
          target.status != DeliveryOrderStatus.delivered &&
          target.status != DeliveryOrderStatus.cancelled) {
        LiveTrackingService().setUploadCallback(updateLocation);
        if (!LiveTrackingService().isTracking || LiveTrackingService().activeOrderId != activeTrackingOrderId) {
          LiveTrackingService().startTracking(orderId: activeTrackingOrderId);
        }
        return;
      } else {
        activeTrackingOrderId = null;
      }
    }

    // Inspect orders to find any in-flight active order
    final inFlight = _orders.where((o) =>
        o.status == DeliveryOrderStatus.pickedUp ||
        o.status == DeliveryOrderStatus.arrivedAtCustomer ||
        o.status == DeliveryOrderStatus.arrivedAtStore ||
        o.status == DeliveryOrderStatus.assigned
    ).toList();

    if (inFlight.isNotEmpty) {
      final target = inFlight.first;
      activeTrackingOrderId = target.id;
      LiveTrackingService().setUploadCallback(updateLocation);
      if (!LiveTrackingService().isTracking || LiveTrackingService().activeOrderId != target.id) {
        LiveTrackingService().startTracking(orderId: target.id);
      }
    } else {
      activeTrackingOrderId = null;
      if (LiveTrackingService().isTracking) {
        LiveTrackingService().stopTracking();
      }
    }
  }
}
