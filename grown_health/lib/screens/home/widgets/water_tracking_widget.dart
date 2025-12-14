import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/water_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/water_intake_model.dart';

class WaterTrackingWidget extends ConsumerStatefulWidget {
  const WaterTrackingWidget({super.key});

  @override
  ConsumerState<WaterTrackingWidget> createState() =>
      _WaterTrackingWidgetState();
}

class _WaterTrackingWidgetState extends ConsumerState<WaterTrackingWidget> {
  WaterTodayResponse? _todayData;
  bool _loading = false;
  int _currentGlasses = 0;
  int _totalGlasses = 8;

  @override
  void initState() {
    super.initState();
    _loadWaterData();
  }

  Future<void> _loadWaterData() async {
    final token = ref.read(authProvider).user?.token;

    if (token == null || token.isEmpty) {
      return;
    }

    setState(() => _loading = true);

    try {
      final waterService = WaterService(token);
      debugPrint('💧 Fetching water data...');

      try {
        final data = await waterService.getTodayWaterIntake();
        debugPrint('💧 Water data received: ${data.count}/${data.goal}');
        if (mounted) {
          setState(() {
            _todayData = data;
            _currentGlasses = data.count;
            _totalGlasses = data.goal;
            _loading = false;
          });
        }
      } catch (e) {
        debugPrint('⚠️ Failed to get water data: $e');
        // Initialize goal if not exists or other error
        try {
          debugPrint('💧 Setting default water goal to 8...');
          await waterService.setWaterGoal(8);
          final data = await waterService.getTodayWaterIntake();
          if (mounted) {
            setState(() {
              _todayData = data;
              _currentGlasses = data.count;
              _totalGlasses = data.goal;
              _loading = false;
            });
          }
        } catch (goalError) {
          debugPrint('❌ Failed to set default goal: $goalError');
          // Fallback to local defaults if network is completely down
          if (mounted) {
            setState(() {
              _currentGlasses = 0;
              _totalGlasses = 8;
              _loading = false;
              // Create a dummy response for UI consistency if needed
              _todayData = const WaterTodayResponse(
                count: 0,
                goal: 8,
                percentage: 0,
                remaining: 8,
                isCompleted: false,
              );
            });
            // Optional: Show offline message
            // ScaffoldMessenger.of(context).showSnackBar(
            //   const SnackBar(content: Text('Offline mode: Using default water goal')),
            // );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Water service error: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _addWater() async {
    final token = ref.read(authProvider).user?.token;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to track water'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final waterService = WaterService(token);
      debugPrint('💧 Adding water glass...');
      final result = await waterService.addWaterGlass();
      debugPrint('💧 Water added: ${result.count}/${result.goal}');

      if (mounted) {
        setState(() {
          _todayData = result;
          _currentGlasses = result.count;
          _totalGlasses = result.goal;
          _loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added 250ml! ${result.count}/${result.goal} glasses',
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to add water: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMl = _currentGlasses * 250;
    final totalMl = _totalGlasses * 250;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side - Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Water Intake',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _loading ? null : _addWater,
                  child: Text(
                    'Add',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFAA3D50),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right side - Glass visualization
          Row(
            children: [
              Text(
                '${currentMl}ml / ${totalMl}ml',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              // Glass icons
              Row(
                children: List.generate(_totalGlasses, (index) {
                  final isFilled = index < _currentGlasses;
                  return Container(
                    margin: const EdgeInsets.only(left: 2),
                    child: _buildGlass(isFilled),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlass(bool filled) {
    return Container(
      width: 12,
      height: 40,
      decoration: BoxDecoration(
        color: filled ? const Color(0xFFE57373) : Colors.white,
        border: Border.all(color: const Color(0xFFE57373), width: 1.5),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
