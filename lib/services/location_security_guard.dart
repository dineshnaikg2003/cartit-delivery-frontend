import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

class LocationSecurityGuard {
  static Position? _lastPosition;
  static DateTime? _lastTimestamp;
  static StreamSubscription<Position>? _positionSubscription;

  // Security thresholds
  static const double maxSpeedKmH = 160.0; // Impossible speed for delivery
  static const double maxInstantTeleportKm = 3.0; // Instant jump threshold
  static const int minTeleportSeconds = 3;

  /// Starts listening to real-time GPS stream for Fake GPS & Morphing detection.
  static void startSecurityMonitoring(
    BuildContext context, {
    required Function(String reason) onViolationDetected,
  }) {
    _positionSubscription?.cancel();

    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      // 1. Check for Mocked / Fake GPS Location flag
      if (position.isMocked) {
        onViolationDetected('Fake GPS / Mock Location Spoofing Detected!');
        if (context.mounted) {
          _terminateApp(
            context,
            'Mock Location (Fake GPS) is active on this device.',
          );
        }
        return;
      }

      // 2. Check for Location Morphing / Teleportation Anomaly
      if (_lastPosition != null && _lastTimestamp != null) {
        double distanceMeters = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        int timeDifferenceSeconds =
            DateTime.now().difference(_lastTimestamp!).inSeconds;
        if (timeDifferenceSeconds <= 0) timeDifferenceSeconds = 1;

        double distanceKm = distanceMeters / 1000.0;
        double speedKmH = (distanceKm / timeDifferenceSeconds) * 3600;

        // Teleportation / Morphing check
        if (distanceKm > maxInstantTeleportKm &&
            timeDifferenceSeconds <= minTeleportSeconds) {
          onViolationDetected(
            'Location Morphing Anomaly Detected! ($distanceKm km jump in $timeDifferenceSeconds sec)',
          );
          if (context.mounted) {
            _terminateApp(
              context,
              'Impossible Location Morphing / Teleportation Detected.',
            );
          }
          return;
        }

        if (speedKmH > maxSpeedKmH) {
          onViolationDetected(
            'Excessive Speed Anomaly Detected! (${speedKmH.toStringAsFixed(0)} km/h)',
          );
          if (context.mounted) {
            _terminateApp(
              context,
              'GPS Velocity Anomaly Detected (${speedKmH.toStringAsFixed(0)} km/h).',
            );
          }
          return;
        }
      }

      _lastPosition = position;
      _lastTimestamp = DateTime.now();
    }, onError: (_) {
      // Handled silently
    });
  }

  static void stopMonitoring() {
    _positionSubscription?.cancel();
  }

  /// Displays security lock dialog and terminates the application immediately.
  static void _terminateApp(BuildContext context, String reason) {
    _positionSubscription?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color(0xFF1E1010),
          title: const Row(
            children: [
              Icon(Icons.security, color: Colors.redAccent, size: 28),
              SizedBox(width: 10),
              Text(
                'SECURITY LOCKOUT',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fake GPS / Location Morphing Detected!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$reason\n\nTo ensure fair delivery partner allocation and system security, the CartIT Delivery app will now terminate.',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                SystemNavigator.pop();
                exit(0);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'EXIT APP NOW',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
