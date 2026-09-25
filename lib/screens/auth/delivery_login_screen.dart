import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/duty_provider.dart';
import '../main/main_navigation_screen.dart';
import 'delivery_register_screen.dart';

class DeliveryLoginScreen extends StatefulWidget {
  const DeliveryLoginScreen({super.key});

  @override
  State<DeliveryLoginScreen> createState() => _DeliveryLoginScreenState();
}

class _DeliveryLoginScreenState extends State<DeliveryLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _errorMessage;

  Timer? _resendTimer;
  int _resendCountdown = 30;
  bool _canResendOtp = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() {
      _resendCountdown = 30;
      _canResendOtp = false;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 1) {
        setState(() => _resendCountdown--);
      } else {
        _resendTimer?.cancel();
        setState(() => _canResendOtp = true);
      }
    });
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      setState(() {
        _errorMessage = 'Please enter a valid 10-digit Indian mobile number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    HapticFeedback.lightImpact();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendOtp(phone);

    setState(() => _isLoading = false);

    if (success) {
      setState(() {
        _isOtpSent = true;
        _errorMessage = null;
      });
      _startResendCountdown();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'OTP sent to +91 $phone (Dev code: 123456)',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else {
      // In case server OTP request failed, check if we still want to allow testing
      setState(() {
        _isOtpSent = true; // Still allow testing with mock OTP 123456
        _errorMessage = authProvider.errorMessage;
      });
      _startResendCountdown();
    }
  }

  Future<void> _verifyAndLogin() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      setState(() {
        _errorMessage = 'Please enter the 6-digit verification code';
      });
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dutyProvider = Provider.of<DutyProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await authProvider.loginWithPhoneAndOtp(
      _phoneController.text,
      otp,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      HapticFeedback.mediumImpact();

      // Sync partner data with duty provider
      if (authProvider.currentUser != null) {
        final user = authProvider.currentUser!;
        dutyProvider.updatePartnerDetails(
          id: user.id,
          name: user.name,
          phone: user.phone,
          vehicleNumber: user.vehicleNumber,
          hubName: user.hubName,
          photoPath: user.profilePhotoUrl,
        );
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else {
      setState(() {
        _errorMessage = authProvider.errorMessage ?? 'Invalid verification code';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final dutyProvider = Provider.of<DutyProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Brand Logo & Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.two_wheeler,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CartIT Delivery',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.darkTitle : AppColors.title,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'RIDER PARTNER APP',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Text(
                _isOtpSent ? 'Verify Mobile OTP' : 'Partner Sign In',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTitle : AppColors.title,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isOtpSent
                    ? 'Code sent to +91 ${_phoneController.text}. Enter 6-digit OTP to continue.'
                    : 'Enter your registered 10-digit mobile number to access your delivery dashboard.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                ),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (!_isOtpSent) ...[
                // Phone input
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkCardBorder : AppColors.border,
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        '+91',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTitle : AppColors.title,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const SizedBox(
                        height: 24,
                        child: VerticalDivider(thickness: 1.5),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? AppColors.darkTitle : AppColors.title,
                          ),
                          decoration: const InputDecoration(
                            hintText: '98765 43210',
                            border: InputBorder.none,
                            counterText: '',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'GET VERIFICATION CODE',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ] else ...[
                // OTP Input
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 10,
                  ),
                  decoration: InputDecoration(
                    hintText: '••••••',
                    hintStyle: const TextStyle(letterSpacing: 10),
                    filled: true,
                    fillColor:
                        isDark ? AppColors.darkSurface : AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color:
                            isDark ? AppColors.darkCardBorder : AppColors.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isOtpSent = false;
                          _errorMessage = null;
                        });
                      },
                      child: const Text(
                        'Change Number',
                        style: TextStyle(
                          color: AppColors.subtitle,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _canResendOtp ? _sendOtp : null,
                      child: Text(
                        _canResendOtp
                            ? 'Resend OTP'
                            : 'Resend in ${_resendCountdown}s',
                        style: TextStyle(
                          color: _canResendOtp
                              ? AppColors.primary
                              : AppColors.subtitle,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyAndLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'VERIFY & SIGN IN',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ],

              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 16),

              // Demo Partner Profiles Switcher
              Text(
                'QUICK DEMO PARTNER PROFILES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(AuthProvider.demoPartners.length, (index) {
                final p = AuthProvider.demoPartners[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isDark
                            ? AppColors.darkCardBorder
                            : AppColors.border,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.15),
                        child: const Icon(Icons.person,
                            color: AppColors.primary, size: 18),
                      ),
                      title: Text(
                        p.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTitle : AppColors.title,
                        ),
                      ),
                      subtitle: Text(
                        '${p.id} • ${p.hubName}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkSubtitle
                              : AppColors.subtitle,
                        ),
                      ),
                      trailing: const Icon(Icons.login,
                          size: 16, color: AppColors.primary),
                      onTap: () async {
                        await authProvider.switchDemoPartner(index);
                        dutyProvider.updatePartnerDetails(
                          id: p.id,
                          name: p.name,
                          phone: p.phone,
                          vehicleNumber: p.vehicleNumber,
                          hubName: p.hubName,
                          photoPath: p.profilePhotoUrl,
                        );
                        if (context.mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const MainNavigationScreen(),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'New to CartIT Delivery? ',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DeliveryRegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Register as Partner',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
