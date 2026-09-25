import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/auth_models.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  static const String _keyToken = 'cartit_delivery_jwt_token';
  static const String _keyPartner = 'cartit_delivery_partner_user';
  static const String _keyPhone = 'cartit_delivery_phone';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

  Future<void> savePartner(DeliveryPartnerUser partner) async {
    final jsonStr = jsonEncode(partner.toJson());
    await _storage.write(key: _keyPartner, value: jsonStr);
    await _storage.write(key: _keyPhone, value: partner.phone);
  }

  Future<DeliveryPartnerUser?> getPartner() async {
    try {
      final jsonStr = await _storage.read(key: _keyPartner);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return DeliveryPartnerUser.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getPhone() async {
    return await _storage.read(key: _keyPhone);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
