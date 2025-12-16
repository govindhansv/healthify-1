import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:grown_health/core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 2;
  bool _isLoading = false;

  // Step 1 fields
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  String? _selectedGender;

  // Step 2 selection
  String? _selectedGoal;

  final List<Map<String, dynamic>> _goals = [
    {'id': 'fit', 'label': 'Get fit', 'icon': Icons.fitness_center_rounded},
    {'id': 'active', 'label': 'Be Active', 'icon': Icons.favorite_rounded},
    {
      'id': 'health',
      'label': 'Be Healthy',
      'icon': Icons.health_and_safety_rounded,
    },
    {'id': 'balance', 'label': 'Find Balance', 'icon': Icons.balance_rounded},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      if (_currentPage == 0) {
        final name = _nameController.text.trim();
        final age = _ageController.text.trim();
        final weight = _weightController.text.trim();
        final height = _heightController.text.trim();

        if (name.isEmpty) {
          SnackBarUtils.showWarning(context, 'Please enter your name');
          return;
        }
        if (age.isEmpty || int.tryParse(age) == null) {
          SnackBarUtils.showWarning(context, 'Please enter a valid age');
          return;
        }
        if (weight.isEmpty || double.tryParse(weight) == null) {
          SnackBarUtils.showWarning(context, 'Please enter a valid weight');
          return;
        }
        if (height.isEmpty || double.tryParse(height) == null) {
          SnackBarUtils.showWarning(context, 'Please enter a valid height');
          return;
        }
        if (_selectedGender == null) {
          SnackBarUtils.showWarning(context, 'Please select your gender');
          return;
        }
      }

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _completeProfileAndGoHome();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _mapGenderToBackend(String? gender) {
    if (gender == null) return 'other';
    switch (gender.toLowerCase()) {
      case 'male':
        return 'male';
      case 'female':
        return 'female';
      case 'prefer not to say':
        return 'other';
      default:
        return 'other';
    }
  }

  Future<void> _completeProfileAndGoHome() async {
    final token = ref.read(authProvider).user?.token;
    final userEmail = ref.read(authProvider).user?.email ?? '';

    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim()) ?? 25;
    final weight = double.tryParse(_weightController.text.trim()) ?? 70.0;
    final height = double.tryParse(_heightController.text.trim());
    final gender = _mapGenderToBackend(_selectedGender);

    String? fitnessGoal;
    if (_selectedGoal != null) {
      final goalObj = _goals.firstWhere(
        (g) => g['id'] == _selectedGoal,
        orElse: () => {},
      );
      if (goalObj.isNotEmpty) {
        fitnessGoal = goalObj['label'] as String;
      }
    }

    setState(() => _isLoading = true);

    try {
      if (token != null && token.isNotEmpty) {
        final profileService = ProfileService(token);
        await profileService.completeProfile(
          name: name.isNotEmpty ? name : 'User',
          age: age,
          gender: gender,
          weight: weight,
          height: height,
          fitnessGoal: fitnessGoal,
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      if (name.isNotEmpty) {
        await prefs.setString('userName', name);
      }

      final profileData = {
        'name': name,
        'age': age,
        'gender': gender,
        'weight': weight,
        'height': height,
        'fitnessGoal': fitnessGoal,
        'isProfileComplete': true,
        'profileCompleted': true,
      };
      await prefs.setString('profile_data_$userEmail', jsonEncode(profileData));

      ref.read(authProvider.notifier).setProfileCompleted(true);

      if (!mounted) return;

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      final errorMsg = e.toString().replaceFirst('Exception: ', '');

      // ignore: use_build_context_synchronously
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Profile Sync Issue'),
          content: Text(
            'Could not save profile to server: $errorMsg\n\n'
            'Your profile will be saved locally. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Try Again'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue Anyway'),
            ),
          ],
        ),
      );

      if (shouldProceed == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        if (name.isNotEmpty) {
          await prefs.setString('userName', name);
        }

        final profileData = {
          'name': name,
          'age': age,
          'gender': gender,
          'weight': weight,
          'height': height,
          'fitnessGoal': fitnessGoal,
          'isProfileComplete': true,
          'profileCompleted': true,
        };
        await prefs.setString(
          'profile_data_$userEmail',
          jsonEncode(profileData),
        );

        ref.read(authProvider.notifier).setProfileCompleted(true);

        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
        }
      }
    }
  }

  void _showGenderPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Select gender',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.black,
                ),
              ),
              const SizedBox(height: 24),
              _buildGenderOption('Male'),
              _buildGenderOption('Female'),
              _buildGenderOption('Prefer not to say'),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGenderOption(String gender) {
    return InkWell(
      onTap: () {
        setState(() => _selectedGender = gender);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Text(
              gender,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.black87,
              ),
            ),
            const Spacer(),
            if (_selectedGender == gender)
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.accentColor,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Slightly cleaner white
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [_buildStep1(), _buildStep2()],
              ),
            ),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _currentPage > 0 ? _prevPage : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _currentPage > 0 ? 1.0 : 0.0,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.grey200, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.black,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / _totalPages,
                backgroundColor: AppTheme.grey100,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.accentColor,
                ),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: _isLoading ? null : _skipAndGoHome,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.grey500,
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  Future<void> _skipAndGoHome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);

    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
  }

  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _nextPage,
          style:
              ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ).copyWith(
                shadowColor: MaterialStateProperty.all(
                  AppTheme.accentColor.withOpacity(0.3),
                ),
                elevation: MaterialStateProperty.all(8),
              ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppTheme.white,
                  ),
                )
              : Text(
                  _currentPage < _totalPages - 1 ? 'Next' : 'Complete Setup',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'Tell us about\nyourself',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppTheme.black,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'To give you a better experience we need\nto know your gender',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.grey600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),

          // Gender Selector
          GestureDetector(
            onTap: _showGenderPicker,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _selectedGender != null
                          ? AppTheme.accentColor.withOpacity(0.1)
                          : AppTheme.grey50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _selectedGender == 'Male'
                          ? Icons.male_rounded
                          : _selectedGender == 'Female'
                          ? Icons.female_rounded
                          : Icons.person_rounded,
                      color: _selectedGender != null
                          ? AppTheme.accentColor
                          : AppTheme.grey400,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedGender ?? 'Select Gender',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _selectedGender != null
                          ? AppTheme.black
                          : AppTheme.grey400,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          _buildRoundedInput(
            controller: _nameController,
            label: 'Name',
            hint: 'Your Name',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildRoundedInput(
                  controller: _ageController,
                  label: 'Age',
                  hint: '25',
                  icon: Icons.calendar_today_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRoundedInput(
                  controller: _weightController,
                  label: 'Weight',
                  hint: '70kg',
                  icon: Icons.monitor_weight_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRoundedInput(
            controller: _heightController,
            label: 'Height',
            hint: '175cm',
            icon: Icons.height_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRoundedInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.grey500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.accentColor),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.black,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: hint,
                    hintStyle: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.grey300,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'What is your\nmain goal?',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppTheme.black,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This helps us create your personalized\nplan',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.grey600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ..._goals.map((goal) {
            final isSelected = _selectedGoal == goal['id'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () =>
                    setState(() => _selectedGoal = goal['id'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.accentColor : AppTheme.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? AppTheme.accentColor.withOpacity(0.3)
                            : Colors.black.withOpacity(0.04),
                        blurRadius: isSelected ? 20 : 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.white.withOpacity(0.2)
                              : AppTheme.grey50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          goal['icon'] as IconData,
                          color: isSelected ? AppTheme.white : AppTheme.black,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        goal['label'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppTheme.white : AppTheme.black,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 14,
                            color: AppTheme.accentColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
