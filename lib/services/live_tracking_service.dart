import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum LocationPermissionState {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

typedef LocationUploadCallback = Future<void> Function({
  String? orderId,
  required double latitude,
  required double longitude,
  double? accuracy,
  double? speed,
  double? heading,
  int? timestamp,
});

class LiveTrackingService {
  static final LiveTrackingService _instance = LiveTrackingService._internal();
  factory LiveTrackingService() => _instance;
  LiveTrackingService._internal();

  StreamSubscription<Position>? _positionSubscription;
  Position? _lastValidPosition;
  DateTime? _lastUploadTime;
  double? _lastUploadedLat;
  double? _lastUploadedLng;

  String? _activeOrderId;
  bool _isTracking = false;
  LocationUploadCallback? _uploadCallback;

  bool get isTracking => _isTracking;
  String? get activeOrderId => _activeOrderId;

  /// Sets the callback function used to upload location data to the backend.
  void setUploadCallback(LocationUploadCallback callback) {
    _uploadCallback = callback;
  }

  /// Check location service status and request location permissions cleanly.
  Future<LocationPermissionState> checkAndRequestPermissions() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationPermissionState.serviceDisabled;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationPermissionState.denied;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationPermissionState.deniedForever;
      }

      return LocationPermissionState.granted;
    } catch (e) {
      debugPrint('[LiveTrackingService] Permission check exception: $e');
      return LocationPermissionState.denied;
    }
  }

  /// Start live GPS tracking for an active order.
  Future<bool> startTracking({
    String? orderId,
    Function(String reason)? onSecurityViolation,
  }) async {
    _activeOrderId = orderId;

    LocationPermissionState permState = await checkAndRequestPermissions();
    if (permState != LocationPermissionState.granted) {
      debugPrint('[LiveTrackingService] Location permission not granted: $permState');
      return false;
    }

    // Cancel existing stream to prevent duplicate listeners
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 3),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: "CartIT Live Delivery Active",
          notificationText: "Broadcasting real-time GPS coordinates for active order",
          notificationIcon: AndroidResource(name: 'mipmap/launcher_icon'),
          enableWakeLock: true,
        ),
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );
    }

    _isTracking = true;

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) => _processPositionUpdate(position, onSecurityViolation),
      onError: (error) {
        debugPrint('[LiveTrackingService] GPS stream error: $error');
      },
    );

    debugPrint('[LiveTrackingService] Started tracking for order: $orderId');
    return true;
  }

  /// Process incoming location point with accuracy filtering, timestamp verification, and jump checks.
  void _processPositionUpdate(
    Position position,
    Function(String reason)? onSecurityViolation,
  ) {
    // 1. Anti-Mocking / Fake GPS Check
    if (position.isMocked) {
      onSecurityViolation?.call('Mock Location / Fake GPS detected!');
      return;
    }

    // 2. Filter out poor accuracy fixes (> 50 meters)
    if (position.accuracy > 50.0) {
      debugPrint('[LiveTrackingService] Discarded low accuracy fix: ${position.accuracy}m');
      return;
    }

    // 3. Filter out stale timestamps (> 15 seconds old)
    DateTime posTime = position.timestamp;
    if (DateTime.now().difference(posTime).inSeconds.abs() > 15) {
      debugPrint('[LiveTrackingService] Discarded stale position point');
      return;
    }

    // 4. Anomaly & Velocity Jump Check (Max 160 km/h or >3km jump in 3s)
    if (_lastValidPosition != null) {
      double distanceMeters = Geolocator.distanceBetween(
        _lastValidPosition!.latitude,
        _lastValidPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      int timeDiffSec = posTime.difference(_lastValidPosition!.timestamp).inSeconds.abs();
      if (timeDiffSec <= 0) timeDiffSec = 1;

      double speedKmH = (distanceMeters / 1000.0 / timeDiffSec) * 3600;

      if (distanceMeters > 3000 && timeDiffSec <= 3) {
        onSecurityViolation?.call('Instant location morphing jump detected');
        return;
      }

      if (speedKmH > 160.0) {
        debugPrint('[LiveTrackingService] Excessive speed jump discarded: ${speedKmH.toStringAsFixed(0)} km/h');
        return;
      }
    }

    // 5. Debounce / Duplicate upload prevention (Min 3 seconds interval or 5m movement)
    if (_lastUploadTime != null && _lastUploadedLat != null && _lastUploadedLng != null) {
      int secSinceLastUpload = DateTime.now().difference(_lastUploadTime!).inSeconds;
      double distFromLastUpload = Geolocator.distanceBetween(
        _lastUploadedLat!,
        _lastUploadedLng!,
        position.latitude,
        position.longitude,
      );

      if (secSinceLastUpload < 3 && distFromLastUpload < 5.0) {
        return; // Skip duplicate / throttled point
      }
    }

    _lastValidPosition = position;
    _lastUploadTime = DateTime.now();
    _lastUploadedLat = position.latitude;
    _lastUploadedLng = position.longitude;

    // Dispatch upload to backend
    if (_uploadCallback != null) {
      _uploadCallback!(
        orderId: _activeOrderId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        timestamp: position.timestamp.millisecondsSinceEpoch,
      ).catchError((err) {
        debugPrint('[LiveTrackingService] Upload error: $err');
      });
    }
  }

  /// Stop live GPS tracking and cancel position stream.
  Future<void> stopTracking() async {
    _isTracking = false;
    _activeOrderId = null;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _lastValidPosition = null;
    _lastUploadTime = null;
    _lastUploadedLat = null;
    _lastUploadedLng = null;
    debugPrint('[LiveTrackingService] Tracking stopped');
  }
}
