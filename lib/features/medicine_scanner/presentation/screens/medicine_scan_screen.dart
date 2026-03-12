import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/medicine_model.dart';
import '../../providers/medicine_scan_provider.dart';
import 'medicine_result_screen.dart';

/// Design tokens matching MemoCare's premium UI
class _DS {
  // Warm, calming palette — accessible for dementia patients
  static const Color bgDeep = Color(0xFF0F172A);
  static const Color bgCard = Color(0xFF1E293B);
  static const Color bgCardAlt = Color(0xFF263548);
  static const Color accentBlue = Color(0xFF38BDF8);
  static const Color accentTeal = Color(0xFF2DD4BF);
  static const Color accentAmber = Color(0xFFFBBF24);
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color successGreen = Color(0xFF34D399);
  static const Color errorRed = Color(0xFFF87171);

  static const double radiusLg = 24;
  static const double radiusMd = 16;
  static const double radiusSm = 12;

  // Extra-large for dementia accessibility
  static const double fontXXL = 32;
  static const double fontXL = 26;
  static const double fontLg = 20;
  static const double fontMd = 17;
  static const double fontSm = 14;

  static const double buttonHeight = 72;
  static const double iconSizeLg = 40;
  static const double iconSizeMd = 28;
}

class MedicineScanScreen extends ConsumerStatefulWidget {
  const MedicineScanScreen({super.key});

  static const routeName = '/medicine-scan';

  @override
  ConsumerState<MedicineScanScreen> createState() => _MedicineScanScreenState();
}

class _MedicineScanScreenState extends ConsumerState<MedicineScanScreen>
    with TickerProviderStateMixin {
  final _picker = ImagePicker();
  File? _selectedImage;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1280,
        maxHeight: 1280,
      );
      if (picked == null) return;

      setState(() => _selectedImage = File(picked.path));

      // Immediately start analysis
      await ref
          .read(medicineScanProvider.notifier)
          .analyzeImage(File(picked.path));
    } catch (e) {
      if (mounted) {
        _showError('Could not access camera. Please try again.');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: _DS.fontMd,
            color: _DS.textPrimary,
          ),
        ),
        backgroundColor: _DS.bgCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_DS.radiusSm),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(medicineScanProvider);

    // Navigate to result when scan succeeds
    ref.listen<MedicineScanState>(medicineScanProvider, (prev, next) {
      next.whenOrNull(
        success: (medicine) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, animation, __) =>
                  MedicineResultScreen(medicine: medicine),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        },
        error: (message) => _showError(message),
      );
    });

    return Scaffold(
      backgroundColor: _DS.bgDeep,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: scanState.maybeWhen(
            analyzing: () => _buildAnalyzingView(),
            orElse: () => _buildScanView(),
          ),
        ),
      ),
    );
  }

  // ── MAIN SCAN VIEW ──────────────────────────────────────────────────────────

  Widget _buildScanView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildImagePreview(),
          const Spacer(),
          _buildInstructionCard(),
          const SizedBox(height: 28),
          _buildActionButtons(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            ref.read(medicineScanProvider.notifier).reset();
            Navigator.of(context).maybePop();
          },
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _DS.bgCard,
              borderRadius: BorderRadius.circular(_DS.radiusSm),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _DS.textPrimary,
              size: _DS.iconSizeMd,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Scan Medicine',
              style: TextStyle(
                color: _DS.textPrimary,
                fontSize: _DS.fontXL,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Point camera at medicine label',
              style: TextStyle(
                color: _DS.textSecondary,
                fontSize: _DS.fontSm,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Medicine pill icon accent
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_DS.accentBlue, _DS.accentTeal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(_DS.radiusSm),
          ),
          child: const Icon(
            Icons.medication_rounded,
            color: Colors.white,
            size: _DS.iconSizeMd,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _selectedImage != null
          ? _buildSelectedImagePreview()
          : _buildPlaceholderPreview(),
    );
  }

  Widget _buildPlaceholderPreview() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        key: const ValueKey('placeholder'),
        height: 280,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _DS.bgCard,
          borderRadius: BorderRadius.circular(_DS.radiusLg),
          border: Border.all(
            color: _DS.accentBlue.withOpacity(0.35),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: _DS.accentBlue.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: _DS.accentBlue,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No photo yet',
              style: TextStyle(
                color: _DS.textSecondary,
                fontSize: _DS.fontLg,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap a button below to start',
              style: TextStyle(
                color: _DS.textSecondary,
                fontSize: _DS.fontSm,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedImagePreview() {
    return Stack(
      key: const ValueKey('image'),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(_DS.radiusLg),
          child: Image.file(
            _selectedImage!,
            height: 280,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        // Scanning overlay gradient
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_DS.radiusLg),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  _DS.bgDeep.withOpacity(0.4),
                ],
              ),
            ),
          ),
        ),
        // Retake button
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: () => setState(() => _selectedImage = null),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _DS.bgDeep.withOpacity(0.8),
                borderRadius: BorderRadius.circular(_DS.radiusSm),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, color: _DS.textPrimary, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Retake',
                    style: TextStyle(
                      color: _DS.textPrimary,
                      fontSize: _DS.fontSm,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _DS.accentAmber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(_DS.radiusMd),
        border: Border.all(
          color: _DS.accentAmber.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_rounded,
            color: _DS.accentAmber,
            size: 30,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Good photo tips',
                  style: TextStyle(
                    color: _DS.accentAmber,
                    fontSize: _DS.fontMd,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Make sure the medicine label is clearly visible and well-lit for best results.',
                  style: TextStyle(
                    color: _DS.textSecondary,
                    fontSize: _DS.fontSm,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // PRIMARY – Take photo with camera
        _BigActionButton(
          icon: Icons.camera_alt_rounded,
          label: 'Take a Photo',
          subtitle: 'Use your camera',
          gradient: const LinearGradient(
            colors: [_DS.accentBlue, _DS.accentTeal],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          onTap: () => _pickImage(ImageSource.camera),
        ),
        const SizedBox(height: 14),
        // SECONDARY – Choose from gallery
        _BigActionButton(
          icon: Icons.photo_library_rounded,
          label: 'Choose from Gallery',
          subtitle: 'Pick an existing photo',
          gradient: LinearGradient(
            colors: [
              _DS.accentTeal.withOpacity(0.8),
              _DS.accentBlue.withOpacity(0.6),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          onTap: () => _pickImage(ImageSource.gallery),
        ),
      ],
    );
  }

  // ── ANALYZING VIEW ──────────────────────────────────────────────────────────

  Widget _buildAnalyzingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(_DS.radiusLg),
                child: Image.file(
                  _selectedImage!,
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 40),
            ],
            // Animated scanning indicator
            _ScanningIndicator(),
            const SizedBox(height: 32),
            const Text(
              'Reading Medicine...',
              style: TextStyle(
                color: _DS.textPrimary,
                fontSize: _DS.fontXL,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please wait a moment',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _DS.textSecondary,
                fontSize: _DS.fontMd,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── BIG ACTION BUTTON ────────────────────────────────────────────────────────

class _BigActionButton extends StatefulWidget {
  const _BigActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  State<_BigActionButton> createState() => _BigActionButtonState();
}

class _BigActionButtonState extends State<_BigActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: _DS.buttonHeight,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(_DS.radiusMd),
            boxShadow: [
              BoxShadow(
                color: _DS.accentBlue.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    widget.icon,
                    color: Colors.white,
                    size: _DS.iconSizeMd,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: _DS.fontLg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: _DS.fontSm,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── SCANNING INDICATOR ───────────────────────────────────────────────────────

class _ScanningIndicator extends StatefulWidget {
  @override
  State<_ScanningIndicator> createState() => _ScanningIndicatorState();
}

class _ScanningIndicatorState extends State<_ScanningIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _rotateCtrl;
  late final AnimationController _scaleCtrl;

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer rotating ring
          RotationTransition(
            turns: _rotateCtrl,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    _DS.accentBlue,
                    _DS.accentTeal,
                    _DS.accentBlue.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          // Inner pulsing circle
          ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut),
            ),
            child: Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _DS.bgDeep,
              ),
              child: const Icon(
                Icons.document_scanner_rounded,
                color: _DS.accentBlue,
                size: 44,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
