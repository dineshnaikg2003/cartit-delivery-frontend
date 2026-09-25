import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../app/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/duty_provider.dart';
import '../main/main_navigation_screen.dart';

class DeliveryRegisterScreen extends StatefulWidget {
  const DeliveryRegisterScreen({super.key});

  @override
  State<DeliveryRegisterScreen> createState() => _DeliveryRegisterScreenState();
}

class _DeliveryRegisterScreenState extends State<DeliveryRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _vehicleNoController = TextEditingController();

  XFile? _profileImage;
  String _selectedVehicleType = 'Electric Scooter (EV)';
  String _selectedHub = 'Koramangala Dark Store #04';
  bool _isUploadingDocs = false;
  bool _isDocUploaded = false;
  bool _isSubmitting = false;

  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = image;
      });
      if (mounted) {
        Provider.of<DutyProvider>(context, listen: false)
            .setProfilePicPath(image.path);
      }
    }
  }

  final List<String> _vehicleTypes = [
    'Electric Scooter (EV)',
    'Motorbike',
    'Scooter',
    'Bicycle',
  ];

  final List<String> _hubs = [
    'Koramangala Dark Store #04',
    'HSR Layout Hub #02',
    'Indiranagar Dark Store #01',
    'BTM Layout Hub #06',
    'Whitefield Dark Store #09',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _licenseController.dispose();
    _vehicleNoController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isDocUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your Driving License or ID Proof.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dutyProvider = Provider.of<DutyProvider>(context, listen: false);

    final success = await authProvider.registerPartner(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      vehicleType: _selectedVehicleType,
      vehicleNumber: _vehicleNoController.text.trim(),
      hubName: _selectedHub,
      licenseNumber: _licenseController.text.trim(),
      photoPath: _profileImage?.path,
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      final user = authProvider.currentUser;
      if (user != null) {
        dutyProvider.updatePartnerDetails(
          id: user.id,
          name: user.name,
          phone: user.phone,
          vehicleNumber: user.vehicleNumber,
          hubName: user.hubName,
          photoPath: user.profilePhotoUrl,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('🎉 Registration Successful! Welcome to CartIT.'),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Registration failed. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        title: Text(
          'Delivery Partner Registration',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTitle : AppColors.title,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0F261B), const Color(0xFF141F1A)]
                        : [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.two_wheeler,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Become a CartIT Partner',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Earn up to ₹35,000/month with 10-min deliveries',
                            style:
                                TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Profile Photo Upload Circle Widget
              Center(
                child: GestureDetector(
                  onTap: _pickProfileImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.15),
                        backgroundImage: _profileImage != null
                            ? FileImage(File(_profileImage!.path))
                                as ImageProvider
                            : null,
                        child: _profileImage == null
                            ? const Icon(Icons.person,
                                size: 52, color: AppColors.primary)
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Tap to upload Profile Picture',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Personal Details Section
              _buildSectionTitle('Personal Information', isDark),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                style: TextStyle(
                    color: isDark ? AppColors.darkTitle : AppColors.title),
                decoration: _inputDecoration(
                    'Full Name (As per Aadhar)', Icons.person, isDark),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter full name'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(
                    color: isDark ? AppColors.darkTitle : AppColors.title),
                decoration: _inputDecoration(
                    '10-Digit Mobile Number', Icons.phone, isDark),
                validator: (val) => val == null || val.trim().length != 10
                    ? 'Enter valid 10-digit mobile number'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(
                    color: isDark ? AppColors.darkTitle : AppColors.title),
                decoration:
                    _inputDecoration('Email Address', Icons.email, isDark),
                validator: (val) => val == null || !val.contains('@')
                    ? 'Enter valid email address'
                    : null,
              ),
              const SizedBox(height: 20),

              // Vehicle & Hub Section
              _buildSectionTitle('Vehicle & Dark Store Hub', isDark),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedVehicleType,
                dropdownColor:
                    isDark ? AppColors.darkSurface : AppColors.surface,
                style: TextStyle(
                    color: isDark ? AppColors.darkTitle : AppColors.title,
                    fontSize: 14),
                decoration: _inputDecoration(
                    'Vehicle Type', Icons.electric_scooter, isDark),
                items: _vehicleTypes.map((v) {
                  return DropdownMenuItem(value: v, child: Text(v));
                }).toList(),
                onChanged: (val) =>
                    setState(() => _selectedVehicleType = val!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vehicleNoController,
                style: TextStyle(
                    color: isDark ? AppColors.darkTitle : AppColors.title),
                decoration: _inputDecoration(
                    'Vehicle Number (e.g. KA-01-EV-4021)', Icons.pin, isDark),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter vehicle registration number'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _licenseController,
                style: TextStyle(
                    color: isDark ? AppColors.darkTitle : AppColors.title),
                decoration: _inputDecoration(
                    'Driving License Number', Icons.badge, isDark),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter driving license number'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedHub,
                dropdownColor:
                    isDark ? AppColors.darkSurface : AppColors.surface,
                style: TextStyle(
                    color: isDark ? AppColors.darkTitle : AppColors.title,
                    fontSize: 14),
                decoration: _inputDecoration(
                    'Primary Dark Store Hub', Icons.storefront, isDark),
                items: _hubs.map((h) {
                  return DropdownMenuItem(value: h, child: Text(h));
                }).toList(),
                onChanged: (val) => setState(() => _selectedHub = val!),
              ),
              const SizedBox(height: 20),

              // Document Upload Section
              _buildSectionTitle('Document Verification', isDark),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  setState(() => _isUploadingDocs = true);
                  Future.delayed(const Duration(milliseconds: 700), () {
                    if (mounted) {
                      setState(() {
                        _isUploadingDocs = false;
                        _isDocUploaded = true;
                      });
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isDocUploaded
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.darkCardBorder
                              : AppColors.border),
                      width: _isDocUploaded ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isDocUploaded ? Icons.check_circle : Icons.upload_file,
                        color: _isDocUploaded
                            ? AppColors.primary
                            : AppColors.subtitle,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isDocUploaded
                                  ? 'Driving License Uploaded'
                                  : 'Upload Driving License & Aadhar',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.darkTitle
                                    : AppColors.title,
                              ),
                            ),
                            Text(
                              _isDocUploaded
                                  ? 'Verified Front & Back Photo'
                                  : 'Tap to upload photo or document PDF',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkSubtitle
                                    : AppColors.subtitle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isUploadingDocs)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Submit Registration Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'COMPLETE PARTNER REGISTRATION',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.darkTitle : AppColors.title,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
          fontSize: 13,
          color: isDark ? AppColors.darkSubtitle : AppColors.subtitle),
      prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
      filled: true,
      fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: isDark ? AppColors.darkCardBorder : AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: isDark ? AppColors.darkCardBorder : AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
