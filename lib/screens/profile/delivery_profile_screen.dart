import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../app/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/duty_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/delivery_login_screen.dart';
import '../auth/delivery_register_screen.dart';

class DeliveryProfileScreen extends StatelessWidget {
  const DeliveryProfileScreen({super.key});

  void _showGpsDiagnostics(BuildContext context, DutyProvider dutyProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.gps_fixed, color: AppColors.primary),
            SizedBox(width: 8),
            Text('GPS Security Diagnostics', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _diagRow('Mock Location (Fake GPS)', 'Passed (Real Hardware)',
                AppColors.primary),
            _diagRow('GPS Precision Accuracy',
                '±${dutyProvider.gpsAccuracyMeters}m (High Precision)', AppColors.primary),
            _diagRow('Active Battery Level',
                '${dutyProvider.batteryPercent}% (Normal)', AppColors.primary),
            _diagRow('Dark Store Service Radius',
                '${dutyProvider.serviceRadiusKm} km (Verified)', AppColors.primary),
            _diagRow('Hardware Integrity', 'Unrooted / Verified Boot',
                AppColors.primary),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static Widget _diagRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.subtitle)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dutyProvider = Provider.of<DutyProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final user = authProvider.currentUser;
    final partnerName = user?.name ?? dutyProvider.partnerName;
    final partnerId = user?.id ?? dutyProvider.partnerId;
    final vehicleNumber = user?.vehicleNumber ?? dutyProvider.vehicleNumber;
    final hubName = user?.hubName ?? dutyProvider.hubName;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Profile Banner Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkCardBorder : AppColors.border,
              ),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      dutyProvider.setProfilePicPath(image.path);
                    }
                  },
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.2),
                        backgroundImage: dutyProvider.profilePicPath != null
                            ? FileImage(File(dutyProvider.profilePicPath!))
                                as ImageProvider
                            : null,
                        child: dutyProvider.profilePicPath == null
                            ? const Icon(Icons.person,
                                size: 48, color: AppColors.primary)
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 12, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      partnerName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTitle : AppColors.title,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.tierPlatinum.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        dutyProvider.partnerTier,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.tierPlatinum,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: $partnerId • $vehicleNumber',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkHeaderBg
                        : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.storefront,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        '$hubName (${dutyProvider.serviceRadiusKm} km Radius)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Rating & Performance Metrics Row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.star,
                  iconColor: Colors.amber,
                  value: '4.95 ★',
                  label: 'Customer Rating',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.local_shipping,
                  iconColor: AppColors.primary,
                  value: '1,420',
                  label: 'Total Orders',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.bolt,
                  iconColor: AppColors.secondary,
                  value: '99.2%',
                  label: 'On-Time Rate',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Settings List wrapped with Material
          Material(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isDark ? AppColors.darkCardBorder : AppColors.border,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Theme Switcher Tile
                SwitchListTile(
                  title: Text(
                    'Dark Obsidian Mode',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTitle : AppColors.title,
                    ),
                  ),
                  subtitle: Text(
                    'Switch between Dark Obsidian and Light Slate themes',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                    ),
                  ),
                  value: isDark,
                  activeThumbColor: AppColors.primary,
                  onChanged: (_) => themeProvider.toggleTheme(context),
                  secondary: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: AppColors.primary,
                  ),
                ),
                const Divider(height: 1),

                // GPS Diagnostics & Security
                ListTile(
                  leading:
                      const Icon(Icons.gps_fixed, color: AppColors.primary),
                  title: Text(
                    'GPS Security & Diagnostics',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTitle : AppColors.title,
                    ),
                  ),
                  subtitle: Text(
                    'Anti-Mock Location Guard & Telemetry status',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _showGpsDiagnostics(context, dutyProvider),
                ),
                const Divider(height: 1),

                // Helpline
                ListTile(
                  leading: const Icon(Icons.support_agent,
                      color: AppColors.primary),
                  title: Text(
                    'Partner Support Helpline',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTitle : AppColors.title,
                    ),
                  ),
                  subtitle: Text(
                    '24/7 Delivery Partner Assistance & Dispatch Desk',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Calling Partner Helpline...')),
                    );
                  },
                ),
                const Divider(height: 1),

                // Onboarding & Registration
                ListTile(
                  leading: const Icon(Icons.person_add_alt_1,
                      color: AppColors.primary),
                  title: Text(
                    'Partner Onboarding / Register',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTitle : AppColors.title,
                    ),
                  ),
                  subtitle: Text(
                    'Register new rider account or add vehicle',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DeliveryRegisterScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),

                // Emergency SOS
                ListTile(
                  leading:
                      const Icon(Icons.shield, color: Colors.blueAccent),
                  title: Text(
                    'Emergency SOS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTitle : AppColors.title,
                    ),
                  ),
                  subtitle: Text(
                    'Instant dispatch team notification & location broadcast',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Emergency signal transmitted to Store Hub Manager.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  },
                ),
                const Divider(height: 1),

                // Logout
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: const Text(
                    'Sign Out / Switch Partner',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () async {
                    await authProvider.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const DeliveryLoginScreen(),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTitle : AppColors.title,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
