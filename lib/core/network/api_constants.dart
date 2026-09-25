import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  static const String serverHost = "cartit-backend-gqg9.onrender.com";
  static const String baseUrl = "https://$serverHost/api";

  // Auth endpoints
  static const String checkPhone = "/auth/check-phone";
  static const String sendOtp = "/auth/send-otp";
  static const String verifyOtp = "/auth/verify-otp";

  // Delivery / Orders endpoints
  static const String orders = "/orders";

  static String resolveImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';

    String cleanUrl = url.trim();

    if (cleanUrl.contains('localhost:8080')) {
      cleanUrl = cleanUrl.replaceAll('localhost:8080', serverHost);
    }

    if (cleanUrl.contains('127.0.0.1:8080')) {
      cleanUrl = cleanUrl.replaceAll('127.0.0.1:8080', serverHost);
    }

    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      if (cleanUrl.startsWith('/')) {
        return 'https://$serverHost$cleanUrl';
      }
      return 'https://$serverHost/$cleanUrl';
    }

    return cleanUrl;
  }
}
