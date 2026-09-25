import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../auth/delivery_login_screen.dart';
import '../main/main_navigation_screen.dart';

import '../../providers/duty_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dutyProvider = Provider.of<DutyProvider>(context, listen: false);

    await Future.wait([
      authProvider.checkAuthStatus(),
      Future.delayed(const Duration(milliseconds: 1600)),
    ]);

    if (!mounted) return;

    if (authProvider.isAuthenticated && authProvider.currentUser != null) {
      final user = authProvider.currentUser!;
      dutyProvider.updatePartnerDetails(
        id: user.id,
        name: user.name,
        phone: user.phone,
        vehicleNumber: user.vehicleNumber,
        hubName: user.hubName,
        photoPath: user.profilePhotoUrl,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DeliveryLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
              ),
              child: const Icon(
                Icons.two_wheeler,
                size: 72,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'CartIT Delivery',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'EXPRESS 10 MIN DELIVERIES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
