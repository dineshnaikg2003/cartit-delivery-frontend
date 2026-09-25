import 'dart:async';
import 'package:flutter/foundation.dart';

class DutyProvider extends ChangeNotifier {
  bool _isOnDuty = true;
  String _partnerId = 'DEL-8942';
  String _partnerName = 'Rahul Sharma';
  String _partnerPhone = '+91 98765 43210';
  String _vehicleNumber = 'KA-01-EV-4021';
  String _hubName = 'Koramangala Dark Store #04';
  double _serviceRadiusKm = 5.0;
  String? _profilePicPath;

  final int _batteryPercent = 88;
  final int _gpsAccuracyMeters = 3;
  final int _dailyTargetOrders = 15;
  int _shiftSeconds = 14820; // 4 hours 7 mins
  Timer? _timer;

  bool get isOnDuty => _isOnDuty;
  String get partnerId => _partnerId;
  String get partnerName => _partnerName;
  String get partnerPhone => _partnerPhone;
  String get vehicleNumber => _vehicleNumber;
  String get hubName => _hubName;
  double get serviceRadiusKm => _serviceRadiusKm;
  String? get profilePicPath => _profilePicPath;
  int get batteryPercent => _batteryPercent;
  int get gpsAccuracyMeters => _gpsAccuracyMeters;
  int get dailyTargetOrders => _dailyTargetOrders;
  String get partnerTier => 'Platinum Partner';

  void updatePartnerDetails({
    required String id,
    required String name,
    required String phone,
    String? vehicleNumber,
    String? hubName,
    String? photoPath,
  }) {
    _partnerId = id;
    _partnerName = name;
    _partnerPhone = phone;
    if (vehicleNumber != null && vehicleNumber.isNotEmpty) {
      _vehicleNumber = vehicleNumber;
    }
    if (hubName != null && hubName.isNotEmpty) {
      _hubName = hubName;
    }
    if (photoPath != null && photoPath.isNotEmpty) {
      _profilePicPath = photoPath;
    }
    notifyListeners();
  }

  void setProfilePicPath(String? path) {
    _profilePicPath = path;
    notifyListeners();
  }

  void setHub(String hubName) {
    _hubName = hubName;
    notifyListeners();
  }

  void setServiceRadius(double radiusKm) {
    _serviceRadiusKm = radiusKm;
    notifyListeners();
  }

  DutyProvider() {
    _startTimer();
  }

  void toggleDuty() {
    _isOnDuty = !_isOnDuty;
    if (_isOnDuty) {
      _startTimer();
    } else {
      _timer?.cancel();
    }
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isOnDuty) {
        _shiftSeconds++;
        notifyListeners();
      }
    });
  }

  String get formattedShiftTime {
    int hours = _shiftSeconds ~/ 3600;
    int mins = (_shiftSeconds % 3600) ~/ 60;
    int secs = _shiftSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
