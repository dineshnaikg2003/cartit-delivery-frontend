import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:cartit_delivery/screens/profile/delivery_profile_screen.dart';
import 'package:cartit_delivery/providers/theme_provider.dart';
import 'package:cartit_delivery/providers/duty_provider.dart';
import 'package:cartit_delivery/providers/earnings_provider.dart';
import 'package:cartit_delivery/providers/auth_provider.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('DeliveryProfileScreen renders without assertion errors', (WidgetTester tester) async {
    final dutyProvider = DutyProvider();
    final earningsProvider = EarningsProvider();
    final themeProvider = ThemeProvider();
    final authProvider = AuthProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DutyProvider>.value(value: dutyProvider),
          ChangeNotifierProvider<EarningsProvider>.value(value: earningsProvider),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: const MaterialApp(
          home: DeliveryProfileScreen(),
        ),
      ),
    );

    expect(find.byType(DeliveryProfileScreen), findsOneWidget);
    expect(find.text('Dark Obsidian Mode'), findsOneWidget);

    dutyProvider.dispose();
  });
}

