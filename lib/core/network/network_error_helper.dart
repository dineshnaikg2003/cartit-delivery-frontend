import 'package:dio/dio.dart';

class NetworkErrorHelper {
  static String parseError(dynamic error) {
    if (error is DioException) {
      if (error.response?.data != null && error.response?.data is Map) {
        final data = error.response!.data as Map;
        if (data.containsKey('message')) {
          return data['message'].toString();
        }
        if (data.containsKey('error')) {
          return data['error'].toString();
        }
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return "Connection timed out. Please check your network and server.";
        case DioExceptionType.connectionError:
          return "Cannot connect to server. Please check your backend connection.";
        case DioExceptionType.badResponse:
          final code = error.response?.statusCode;
          if (code == 400) return "Invalid input or OTP.";
          if (code == 401) return "Unauthorized. Please check your credentials.";
          if (code == 403) return "Access denied. Partner privileges required.";
          if (code == 404) return "Requested resource not found.";
          if (code == 500) return "Internal server error. Please try again.";
          return "Server error ($code). Please try again.";
        case DioExceptionType.cancel:
          return "Request cancelled.";
        default:
          return "Network error occurred: ${error.message ?? 'Unknown error'}";
      }
    }

    return error?.toString() ?? "An unexpected error occurred.";
  }
}
