import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cartit_delivery/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('AuthProvider Unit Tests', () {
    test('Initial AuthProvider state defaults to unauthenticated', () {
      final provider = AuthProvider();
      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNull);
    });

    test('switchDemoPartner sets partner and authenticates', () async {
      final provider = AuthProvider();
      await provider.switchDemoPartner(0);

      expect(provider.isAuthenticated, true);
      expect(provider.currentUser, isNotNull);
      expect(provider.currentUser?.name, 'Rahul Sharma');
      expect(provider.currentUser?.id, 'DEL-8942');
    });

    test('loginWithPhoneAndOtp with valid test OTP authenticates partner', () async {
      final provider = AuthProvider();
      final success = await provider.loginWithPhoneAndOtp('9876543210', '123456');

      expect(success, true);
      expect(provider.isAuthenticated, true);
      expect(provider.currentUser?.phone, '9876543210');
    });

    test('registerPartner creates new delivery partner profile', () async {
      final provider = AuthProvider();
      final success = await provider.registerPartner(
        name: 'Aman Verma',
        phone: '9812345678',
        email: 'aman.verma@cartit.in',
        vehicleType: 'Electric Scooter (EV)',
        vehicleNumber: 'KA-05-EV-9021',
        hubName: 'Koramangala Dark Store #04',
        licenseNumber: 'KA-05-2023-88192',
      );

      expect(success, true);
      expect(provider.isAuthenticated, true);
      expect(provider.currentUser?.name, 'Aman Verma');
      expect(provider.currentUser?.phone, '9812345678');
      expect(provider.currentUser?.vehicleNumber, 'KA-05-EV-9021');
    });

    test('logout resets session and partner state', () async {
      final provider = AuthProvider();
      await provider.switchDemoPartner(0);
      expect(provider.isAuthenticated, true);

      await provider.logout();
      expect(provider.isAuthenticated, false);
      expect(provider.currentUser, isNull);
    });
  });
}
