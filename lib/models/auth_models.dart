class DeliveryPartnerUser {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String vehicleType;
  final String vehicleNumber;
  final String hubName;
  final String licenseNumber;
  final String? profilePhotoUrl;
  final String status; // ACTIVE, ONBOARDING, SUSPENDED

  DeliveryPartnerUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.hubName,
    required this.licenseNumber,
    this.profilePhotoUrl,
    this.status = 'ACTIVE',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'hubName': hubName,
      'licenseNumber': licenseNumber,
      'profilePhotoUrl': profilePhotoUrl,
      'status': status,
    };
  }

  factory DeliveryPartnerUser.fromJson(Map<String, dynamic> json) {
    return DeliveryPartnerUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      vehicleType: json['vehicleType']?.toString() ?? 'Electric Scooter (EV)',
      vehicleNumber: json['vehicleNumber']?.toString() ?? 'KA-01-EV-4021',
      hubName: json['hubName']?.toString() ?? 'Koramangala Dark Store #04',
      licenseNumber: json['licenseNumber']?.toString() ?? '',
      profilePhotoUrl: json['profilePhotoUrl']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }

  DeliveryPartnerUser copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? vehicleType,
    String? vehicleNumber,
    String? hubName,
    String? licenseNumber,
    String? profilePhotoUrl,
    String? status,
  }) {
    return DeliveryPartnerUser(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      hubName: hubName ?? this.hubName,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      status: status ?? this.status,
    );
  }
}

class SendOtpRequest {
  final String phone;

  SendOtpRequest({required this.phone});

  Map<String, dynamic> toJson() => {
        'phone': phone,
      };
}

class VerifyOtpRequest {
  final String phone;
  final String otp;
  final String? name;
  final String? email;
  final String? role;

  VerifyOtpRequest({
    required this.phone,
    required this.otp,
    this.name,
    this.email,
    this.role,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'phone': phone,
      'otp': otp,
    };
    if (name != null && name!.isNotEmpty) map['name'] = name;
    if (email != null && email!.isNotEmpty) map['email'] = email;
    if (role != null && role!.isNotEmpty) map['role'] = role;
    return map;
  }
}

class UserResponse {
  final int? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? role;

  UserResponse({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.role,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      role: json['role']?.toString(),
    );
  }
}

class AuthResponse {
  final String token;
  final bool isNewUser;
  final UserResponse? user;
  final String? role;

  AuthResponse({
    required this.token,
    required this.isNewUser,
    this.user,
    this.role,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token']?.toString() ?? '',
      isNewUser: json['newUser'] == true,
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? UserResponse.fromJson(json['user'])
          : null,
      role: json['role']?.toString(),
    );
  }
}
