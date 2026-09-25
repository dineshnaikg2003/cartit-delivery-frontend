import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app_colors.dart';
import 'providers/auth_provider.dart';
import 'providers/duty_provider.dart';
import 'providers/delivery_order_provider.dart';
import 'providers/earnings_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash/splash_screen.dart';

import 'dart:io';

class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = DevHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CartITDeliveryApp());
}

class CartITDeliveryApp extends StatelessWidget {
  const CartITDeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DutyProvider()),
        ChangeNotifierProvider(create: (_) => DeliveryOrderProvider()),
        ChangeNotifierProvider(create: (_) => EarningsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'CartIT Delivery',
            debugShowCheckedModeBanner: false,

            // Light Theme Aligned with CartIT
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                primary: AppColors.primary,
                secondary: AppColors.secondary,
                surface: AppColors.surface,
              ),
              scaffoldBackgroundColor: AppColors.background,
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.surface,
                elevation: 0,
                iconTheme: IconThemeData(color: AppColors.title),
              ),
            ),

            // Dark Obsidian Theme Aligned with CartIT
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                brightness: Brightness.dark,
                primary: AppColors.primary,
                secondary: AppColors.secondary,
                surface: AppColors.darkSurface,
              ),
              scaffoldBackgroundColor: AppColors.darkBackground,
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.darkSurface,
                elevation: 0,
                iconTheme: IconThemeData(color: AppColors.darkTitle),
              ),
            ),

            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
