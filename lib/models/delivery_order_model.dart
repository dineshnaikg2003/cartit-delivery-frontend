import 'package:flutter/material.dart';

enum DeliveryOrderStatus {
  assigned,
  arrivedAtStore,
  pickedUp,
  arrivedAtCustomer,
  delivered,
  cancelled,
}

extension DeliveryOrderStatusExtension on DeliveryOrderStatus {
  String get label {
    switch (this) {
      case DeliveryOrderStatus.assigned:
        return 'ASSIGNED';
      case DeliveryOrderStatus.arrivedAtStore:
        return 'AT DARK STORE';
      case DeliveryOrderStatus.pickedUp:
        return 'OUT FOR DELIVERY';
      case DeliveryOrderStatus.arrivedAtCustomer:
        return 'AT DOORSTEP';
      case DeliveryOrderStatus.delivered:
        return 'DELIVERED';
      case DeliveryOrderStatus.cancelled:
        return 'CANCELLED / RETURNED';
    }
  }

  String get nextActionLabel {
    switch (this) {
      case DeliveryOrderStatus.assigned:
        return 'Slide to Reach Store';
      case DeliveryOrderStatus.arrivedAtStore:
        return 'Slide to Confirm Pick Up';
      case DeliveryOrderStatus.pickedUp:
        return 'Slide to Reach Customer';
      case DeliveryOrderStatus.arrivedAtCustomer:
        return 'Verify OTP & Deliver';
      case DeliveryOrderStatus.delivered:
        return 'Completed';
      case DeliveryOrderStatus.cancelled:
        return 'Return Package to Store';
    }
  }

  Color get badgeColor {
    switch (this) {
      case DeliveryOrderStatus.assigned:
        return const Color(0xFF3B82F6);
      case DeliveryOrderStatus.arrivedAtStore:
        return const Color(0xFFFF9800);
      case DeliveryOrderStatus.pickedUp:
        return const Color(0xFF8B5CF6);
      case DeliveryOrderStatus.arrivedAtCustomer:
        return const Color(0xFF06B6D4);
      case DeliveryOrderStatus.delivered:
        return const Color(0xFF00B259);
      case DeliveryOrderStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }
}

class DeliveryOrderItem {
  final String id;
  final String title;
  final String variant;
  final int quantity;
  final double unitPrice;
  final String? imageUrl;
  final bool isVeg;
  final bool isCold; // Cold chain item (needs cooler bag)

  DeliveryOrderItem({
    required this.id,
    required this.title,
    required this.variant,
    required this.quantity,
    required this.unitPrice,
    this.imageUrl,
    this.isVeg = true,
    this.isCold = false,
  });

  double get totalPrice => unitPrice * quantity;

  factory DeliveryOrderItem.fromJson(Map<String, dynamic> json) {
    return DeliveryOrderItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['productName'] ?? 'Item',
      variant: json['variant'] ?? '1 Unit',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'] ?? json['productImage'],
      isVeg: json['isVeg'] ?? true,
      isCold: json['isCold'] ?? false,
    );
  }
}

class DeliveryOrder {
  final String id;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final String? landmark;
  final String addressType; // Home, Work, Other
  final double customerLat;
  final double customerLng;

  final String storeName;
  final String storeAddress;
  final String storeBay; // e.g. 'Bay #04B'
  final String bagBarcode; // e.g. 'BAG-98421-KOR'
  final double storeLat;
  final double storeLng;

  final List<DeliveryOrderItem> items;
  final DeliveryOrderStatus status;
  final String paymentMethod; // COD, ONLINE, UPI
  final bool isPaid;
  final double totalAmount;
  final double cashToCollect;
  final String deliveryInstructions;
  final String estimatedMins;
  final double distanceStoreKm;
  final double distanceCustomerKm;
  final String customerOtp;
  final double riderEarning;
  final double tipAmount;
  final DateTime createdAt;
  final String? cancellationReason;

  DeliveryOrder({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    this.landmark,
    required this.addressType,
    required this.customerLat,
    required this.customerLng,
    required this.storeName,
    required this.storeAddress,
    this.storeBay = 'Bay 03-A',
    this.bagBarcode = 'BAG-CART-042',
    required this.storeLat,
    required this.storeLng,
    required this.items,
    required this.status,
    required this.paymentMethod,
    required this.isPaid,
    required this.totalAmount,
    required this.cashToCollect,
    required this.deliveryInstructions,
    required this.estimatedMins,
    required this.distanceStoreKm,
    required this.distanceCustomerKm,
    required this.customerOtp,
    this.riderEarning = 45.0,
    this.tipAmount = 0.0,
    required this.createdAt,
    this.cancellationReason,
  });

  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  DeliveryOrder copyWith({
    DeliveryOrderStatus? status,
    bool? isPaid,
    double? cashToCollect,
    String? cancellationReason,
    double? tipAmount,
  }) {
    return DeliveryOrder(
      id: id,
      orderNumber: orderNumber,
      customerName: customerName,
      customerPhone: customerPhone,
      deliveryAddress: deliveryAddress,
      landmark: landmark,
      addressType: addressType,
      customerLat: customerLat,
      customerLng: customerLng,
      storeName: storeName,
      storeAddress: storeAddress,
      storeBay: storeBay,
      bagBarcode: bagBarcode,
      storeLat: storeLat,
      storeLng: storeLng,
      items: items,
      status: status ?? this.status,
      paymentMethod: paymentMethod,
      isPaid: isPaid ?? this.isPaid,
      totalAmount: totalAmount,
      cashToCollect: cashToCollect ?? this.cashToCollect,
      deliveryInstructions: deliveryInstructions,
      estimatedMins: estimatedMins,
      distanceStoreKm: distanceStoreKm,
      distanceCustomerKm: distanceCustomerKm,
      customerOtp: customerOtp,
      riderEarning: riderEarning,
      tipAmount: tipAmount ?? this.tipAmount,
      createdAt: createdAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List? ?? [];
    List<DeliveryOrderItem> parsedItems =
        rawItems.map((i) => DeliveryOrderItem.fromJson(i)).toList();

    return DeliveryOrder(
      id: json['id']?.toString() ?? '',
      orderNumber: json['orderNumber'] ?? '#ORD-0000',
      customerName: json['customerName'] ?? json['deliveryName'] ?? 'Customer',
      customerPhone: json['customerPhone'] ?? json['deliveryPhone'] ?? '',
      deliveryAddress:
          json['deliveryAddress'] ?? json['deliveryAddressLine1'] ?? '',
      landmark: json['landmark'] ?? json['deliveryLandmark'],
      addressType: json['addressType'] ?? 'HOME',
      customerLat: (json['customerLat'] as num?)?.toDouble() ?? (json['deliveryLatitude'] as num?)?.toDouble() ?? 12.9716,
      customerLng: (json['customerLng'] as num?)?.toDouble() ?? (json['deliveryLongitude'] as num?)?.toDouble() ?? 77.5946,
      storeName: json['storeName'] ?? 'CartIT Dark Store - Koramangala',
      storeAddress:
          json['storeAddress'] ?? '100 Feet Rd, 4th Block, Koramangala',
      storeBay: json['storeBay'] ?? 'Bay 04B',
      bagBarcode: json['bagBarcode'] ?? 'BAG-${json['orderNumber'] ?? '001'}',
      storeLat: (json['storeLat'] as num?)?.toDouble() ?? (json['storeLatitude'] as num?)?.toDouble() ?? 12.9352,
      storeLng: (json['storeLng'] as num?)?.toDouble() ?? (json['storeLongitude'] as num?)?.toDouble() ?? 77.6245,
      items: parsedItems,
      status: _parseStatus(json['status'] ?? json['orderStatus']),
      paymentMethod: json['paymentMethod'] ?? 'ONLINE',
      isPaid: json['isPaid'] ?? (json['paymentStatus'] == 'SUCCESS'),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      cashToCollect: (json['cashToCollect'] as num?)?.toDouble() ?? 0.0,
      deliveryInstructions: json['deliveryInstructions'] ??
          'Deliver at doorstep. Ring doorbell twice.',
      estimatedMins: json['estimatedMins'] ?? '10-12 mins',
      distanceStoreKm: (json['distanceStoreKm'] as num?)?.toDouble() ?? 1.2,
      distanceCustomerKm:
          (json['distanceCustomerKm'] as num?)?.toDouble() ?? 2.8,
      customerOtp: json['customerOtp'] ?? '4829',
      riderEarning: (json['riderEarning'] as num?)?.toDouble() ?? 45.0,
      tipAmount: (json['tipAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      cancellationReason: json['cancellationReason'],
    );
  }

  static DeliveryOrderStatus _parseStatus(String? statusStr) {
    if (statusStr == null) return DeliveryOrderStatus.assigned;
    switch (statusStr.toUpperCase()) {
      case 'ARRIVED_AT_STORE':
      case 'STORE_ARRIVED':
        return DeliveryOrderStatus.arrivedAtStore;
      case 'PICKED_UP':
      case 'OUT_FOR_DELIVERY':
        return DeliveryOrderStatus.pickedUp;
      case 'ARRIVED_AT_CUSTOMER':
      case 'CUSTOMER_DOORSTEP':
        return DeliveryOrderStatus.arrivedAtCustomer;
      case 'DELIVERED':
      case 'COMPLETED':
        return DeliveryOrderStatus.delivered;
      case 'CANCELLED':
      case 'RETURNED':
        return DeliveryOrderStatus.cancelled;
      default:
        return DeliveryOrderStatus.assigned;
    }
  }
}
