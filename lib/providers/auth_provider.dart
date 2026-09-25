import 'package:flutter/material.dart';
import '../core/network/api_constants.dart';
import '../core/network/api_service.dart';
import '../core/network/network_error_helper.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/auth_models.dart';

export '../models/auth_models.dart' show DeliveryPartnerUser;

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SecureStorageService _storage = SecureStorageService();

  DeliveryPartnerUser? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isPhoneRegistered = true;
  String? _errorMessage;
  String? _currentPhone;

  DeliveryPartnerUser? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isPhoneRegistered => _isPhoneRegistered;
  String? get errorMessage => _errorMessage;
  String? get currentPhone => _currentPhone;

  // Demo partner profiles for quick testing/switching
  static final List<DeliveryPartnerUser> demoPartners = [
    DeliveryPartnerUser(
      id: 'DEL-8942',
      name: 'Rahul Sharma',
      phone: '9876543210',
      email: 'rahul.sharma@cartit.in',
      vehicleType: 'Electric Scooter (Ather 450X)',
      vehicleNumber: 'KA-01-EV-4021',
      hubName: 'Koramangala Dark Store #04',
      licenseNumber: 'KA-05-2021-0089421',
      status: 'ACTIVE',
    ),
    DeliveryPartnerUser(
      id: 'DEL-7104',
      name: 'Vikramaditya Rao',
      phone: '9765432109',
      email: 'vikram.rao@cartit.in',
      vehicleType: 'Hero Electric Optima',
      vehicleNumber: 'KA-03-EV-1120',
      hubName: 'HSR Layout Hub #02',
      licenseNumber: 'KA-03-2020-0071044',
      status: 'ACTIVE',
    ),
    DeliveryPartnerUser(
      id: 'DEL-9011',
      name: 'Ananya Roy',
      phone: '9912377889',
      email: 'ananya.roy@cartit.in',
      vehicleType: 'Honda Activa 6G',
      vehicleNumber: 'KA-04-HB-9011',
      hubName: 'Indiranagar Dark Store #01',
      licenseNumber: 'KA-04-2022-0090112',
      status: 'ACTIVE',
    ),
  ];

  AuthProvider() {
    checkAuthStatus();
  }

  /// Initialize session from secure storage
  Future<void> checkAuthStatus() async {
    final token = await _storage.getToken();
    final partner = await _storage.getPartner();

    if (token != null && token.isNotEmpty && partner != null) {
      _currentUser = partner;
      _currentPhone = partner.phone;
      _isAuthenticated = true;
    } else {
      _currentUser = null;
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  /// Check phone registration and send OTP
  Future<bool> sendOtp(String rawPhone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final phone = _sanitizePhone(rawPhone);
    _currentPhone = phone;

    try {
      // 1. Check if phone is registered
      try {
        final checkRes = await _apiService.client.post(
          ApiConstants.checkPhone,
          data: SendOtpRequest(phone: phone).toJson(),
        );
        if (checkRes.statusCode == 200 && checkRes.data['data'] != null) {
          _isPhoneRegistered = checkRes.data['data'] == true;
        }
      } catch (_) {
        // Backend check phone fallback
        _isPhoneRegistered = true;
      }

      // 2. Request OTP send
      final response = await _apiService.client.post(
        ApiConstants.sendOtp,
        data: SendOtpRequest(phone: phone).toJson(),
      );

      _isLoading = false;
      if (response.statusCode == 200 && response.data['success'] == true) {
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.data['message'] ?? 'Failed to send OTP';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      // In offline / standalone dev mode, allow proceeding
      _errorMessage = NetworkErrorHelper.parseError(e);
      notifyListeners();
      return false;
    }
  }

  /// Verify OTP and login partner
  Future<bool> loginWithPhoneAndOtp(String rawPhone, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final phone = _sanitizePhone(rawPhone);

    try {
      final response = await _apiService.client.post(
        ApiConstants.verifyOtp,
        data: VerifyOtpRequest(
          phone: phone,
          otp: otp.trim(),
        ).toJson(),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final authData = AuthResponse.fromJson(response.data['data']);
        await _storage.saveToken(authData.token);

        final user = authData.user;
        final partnerId = user?.id != null ? 'DEL-${user!.id}' : 'DEL-${(1000 + phone.hashCode % 9000).abs()}';
        final partnerName = user?.name ?? 'Delivery Partner';
        final partnerEmail = user?.email ?? '$phone@cartit.in';

        // Check if existing saved details exist
        final existing = await _storage.getPartner();
        final partner = DeliveryPartnerUser(
          id: partnerId,
          name: partnerName,
          phone: phone,
          email: partnerEmail,
          vehicleType: existing?.vehicleType ?? 'Electric Scooter (EV)',
          vehicleNumber: existing?.vehicleNumber ?? 'KA-01-EV-4021',
          hubName: existing?.hubName ?? 'Koramangala Dark Store #04',
          licenseNumber: existing?.licenseNumber ?? 'KA-05-2023-99881',
          profilePhotoUrl: existing?.profilePhotoUrl,
          status: 'ACTIVE',
        );

        await _storage.savePartner(partner);
        _currentUser = partner;
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        _errorMessage = response.data['message'] ?? 'Invalid verification code.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Fallback for development/testing when backend is unreachable or local test OTP is entered
      if (otp.trim() == '123456' || otp.trim() == '1234') {
        const dummyToken = 'mock_jwt_token_delivery_partner';
        await _storage.saveToken(dummyToken);

        final partner = DeliveryPartnerUser(
          id: 'DEL-${(1000 + phone.hashCode % 9000).abs()}',
          name: 'Delivery Partner',
          phone: phone,
          email: '$phone@cartit.in',
          vehicleType: 'Electric Scooter (EV)',
          vehicleNumber: 'KA-01-EV-4021',
          hubName: 'Koramangala Dark Store #04',
          licenseNumber: 'KA-05-2023-99881',
          status: 'ACTIVE',
        );

        await _storage.savePartner(partner);
        _currentUser = partner;
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      _errorMessage = NetworkErrorHelper.parseError(e);
      notifyListeners();
      return false;
    }
  }

  /// Register a new delivery partner
  Future<bool> registerPartner({
    required String name,
    required String phone,
    required String email,
    required String vehicleType,
    required String vehicleNumber,
    required String hubName,
    required String licenseNumber,
    String? photoPath,
    String otp = '123456',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cleanPhone = _sanitizePhone(phone);

    try {
      final response = await _apiService.client.post(
        ApiConstants.verifyOtp,
        data: VerifyOtpRequest(
          phone: cleanPhone,
          otp: otp.trim(),
          name: name.trim(),
          email: email.trim(),
          role: 'DELIVERY_BOY',
        ).toJson(),
      );

      String token = 'mock_jwt_token_delivery_partner';
      String partnerId = 'DEL-${(1000 + cleanPhone.hashCode % 9000).abs()}';

      if (response.statusCode == 200 && response.data['success'] == true) {
        final authData = AuthResponse.fromJson(response.data['data']);
        token = authData.token;
        if (authData.user?.id != null) {
          partnerId = 'DEL-${authData.user!.id}';
        }
      }

      await _storage.saveToken(token);

      final partner = DeliveryPartnerUser(
        id: partnerId,
        name: name.trim(),
        phone: cleanPhone,
        email: email.trim(),
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber.trim(),
        hubName: hubName,
        licenseNumber: licenseNumber.trim(),
        profilePhotoUrl: photoPath,
        status: 'ACTIVE',
      );

      await _storage.savePartner(partner);
      _currentUser = partner;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Local fallback for standalone testing if backend is offline
      const token = 'mock_jwt_token_delivery_partner';
      await _storage.saveToken(token);

      final partner = DeliveryPartnerUser(
        id: 'DEL-${(1000 + cleanPhone.hashCode % 9000).abs()}',
        name: name.trim(),
        phone: cleanPhone,
        email: email.trim(),
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber.trim(),
        hubName: hubName,
        licenseNumber: licenseNumber.trim(),
        profilePhotoUrl: photoPath,
        status: 'ACTIVE',
      );

      await _storage.savePartner(partner);
      _currentUser = partner;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  /// Switch to a demo partner profile
  Future<void> switchDemoPartner(int index) async {
    if (index >= 0 && index < demoPartners.length) {
      final p = demoPartners[index];
      await _storage.saveToken('demo_token_${p.id}');
      await _storage.savePartner(p);
      _currentUser = p;
      _currentPhone = p.phone;
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  /// Logout and clear storage
  Future<void> logout() async {
    await _storage.clearAll();
    _currentUser = null;
    _isAuthenticated = false;
    _currentPhone = null;
    _errorMessage = null;
    notifyListeners();
  }

  String _sanitizePhone(String phone) {
    String clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.length > 10 && clean.startsWith('91')) {
      clean = clean.substring(2);
    }
    return clean;
  }
}
