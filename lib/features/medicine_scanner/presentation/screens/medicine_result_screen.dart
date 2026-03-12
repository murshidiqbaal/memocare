import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/reminder.dart';
import '../../../patient/presentation/screens/reminders/add_edit_reminder_screen.dart';
import '../../data/models/medicine_model.dart';
import '../../providers/medicine_scan_provider.dart';

// Reuse same design tokens
class _DS {
  static const Color bgDeep = Color(0xFF0F172A);
  static const Color bgCard = Color(0xFF1E293B);
  static const Color bgCardAlt = Color(0xFF263548);
  static const Color accentBlue = Color(0xFF38BDF8);
  static const Color accentTeal = Color(0xFF2DD4BF);
  static const Color accentAmber = Color(0xFFFBBF24);
  static const Color accentPurple = Color(0xFFA78BFA);
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color successGreen = Color(0xFF34D399);
  static const Color errorRed = Color(0xFFF87171);

  static const double radiusLg = 24;
  static const double radiusMd = 16;
  static const double radiusSm = 12;

  static const double fontXXL = 28;
  static const double fontXL = 22;
  static const double fontLg = 16;
  static const double fontMd = 14;
  static const double fontSm = 10;

  static const double buttonHeight = 68;
}

class MedicineResultScreen extends ConsumerStatefulWidget {
  const MedicineResultScreen({super.key, required this.medicine});

  final MedicineInfo medicine;

  @override
  ConsumerState<MedicineResultScreen> createState() =>
      _MedicineResultScreenState();
}

class _MedicineResultScreenState extends ConsumerState<MedicineResultScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DS.bgDeep,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 28),
                        _buildConfidenceBanner(),
                        const SizedBox(height: 20),
                        _buildMedicineCard(),
                        const SizedBox(height: 20),
                        _buildAddReminderPrompt(),
                        const SizedBox(height: 32),
                        _buildBottomActions(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            ref.read(medicineScanProvider.notifier).reset();
            Navigator.of(context).pop();
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
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'Medicine Found',
            style: TextStyle(
              color: _DS.textPrimary,
              fontSize: _DS.fontXL,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_DS.successGreen, _DS.accentTeal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(_DS.radiusSm),
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ],
    );
  }

  // ── CONFIDENCE BANNER ─────────────────────────────────────────────────────

  Widget _buildConfidenceBanner() {
    final conf = widget.medicine.confidence;
    final Color color;
    final String label;
    final IconData icon;

    switch (conf) {
      case RecognitionConfidence.high:
        color = _DS.successGreen;
        label = 'Clearly identified ✓';
        icon = Icons.verified_rounded;
        break;
      case RecognitionConfidence.medium:
        color = _DS.accentAmber;
        label = 'Probably correct — please verify';
        icon = Icons.info_rounded;
        break;
      case RecognitionConfidence.low:
        color = _DS.errorRed;
        label = 'Not sure — please check with caregiver';
        icon = Icons.warning_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(_DS.radiusMd),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: _DS.fontMd,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── MEDICINE CARD ─────────────────────────────────────────────────────────

  Widget _buildMedicineCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _DS.bgCard,
        borderRadius: BorderRadius.circular(_DS.radiusLg),
        border: Border.all(
          color: _DS.accentBlue.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_DS.accentBlue, _DS.accentTeal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.medication_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Medicine Name',
                      style: TextStyle(
                        color: _DS.textSecondary,
                        fontSize: _DS.fontSm,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.medicine.name,
                      style: const TextStyle(
                        color: _DS.textPrimary,
                        fontSize: _DS.fontXL,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFF2D3F55), thickness: 1),
          const SizedBox(height: 20),
          // Info grid
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.scale_rounded,
                  label: 'Dosage',
                  value: widget.medicine.dosage,
                  valueColor: _DS.accentBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── ADD REMINDER PROMPT ───────────────────────────────────────────────────

  Widget _buildAddReminderPrompt() {
    return _DementiaFriendlyButton(
      icon: Icons.alarm_add_rounded,
      label: '⏰  Set a Reminder',
      subtitle: 'I will remind you to take this medicine',
      gradient: const LinearGradient(
        colors: [_DS.accentPurple, Color(0xFF6366F1)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      onTap: () {
        Navigator.of(context)
            .push(
          MaterialPageRoute(
            builder: (context) => AddEditReminderScreen(
              initialTitle: '${widget.medicine.name} ${widget.medicine.dosage}',
              initialType: ReminderType.medication,
            ),
          ),
        )
            .then((_) {
          ref.read(medicineScanProvider.notifier).reset();
          if (mounted) Navigator.of(context).pop();
        });
      },
    );
  }

  // ── BOTTOM ACTIONS ────────────────────────────────────────────────────────

  Widget _buildBottomActions() {
    return Column(
      children: [
        _DementiaFriendlyButton(
          icon: Icons.camera_alt_rounded,
          label: '📷  Scan Another Medicine',
          subtitle: 'Take a new photo',
          gradient: const LinearGradient(
            colors: [
              _DS.bgCard,
              _DS.bgCardAlt,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderColor: _DS.accentBlue.withOpacity(0.4),
          onTap: () {
            ref.read(medicineScanProvider.notifier).reset();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

// ── INFO TILE ─────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _DS.bgCardAlt,
        borderRadius: BorderRadius.circular(_DS.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _DS.textSecondary, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: _DS.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: _DS.fontMd,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── DEMENTIA FRIENDLY BUTTON ───────────────────────────────────────────────

class _DementiaFriendlyButton extends StatefulWidget {
  const _DementiaFriendlyButton({
    this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    this.onTap,
    this.isDisabled = false,
    this.isLoading = false,
    this.borderColor,
  });

  final IconData? icon;
  final String label;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback? onTap;
  final bool isDisabled;
  final bool isLoading;
  final Color? borderColor;

  @override
  State<_DementiaFriendlyButton> createState() =>
      _DementiaFriendlyButtonState();
}

class _DementiaFriendlyButtonState extends State<_DementiaFriendlyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = widget.isDisabled
        ? LinearGradient(
            colors: [Colors.grey.shade800, Colors.grey.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : widget.gradient;

    return GestureDetector(
      onTapDown: widget.isDisabled || widget.isLoading
          ? null
          : (_) => setState(() => _pressed = true),
      onTapUp: widget.isDisabled || widget.isLoading
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: _DS.buttonHeight,
          decoration: BoxDecoration(
            gradient: effectiveGradient,
            borderRadius: BorderRadius.circular(_DS.radiusMd),
            border: widget.borderColor != null
                ? Border.all(color: widget.borderColor!, width: 2)
                : null,
            boxShadow: widget.isDisabled
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (widget.isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else if (widget.icon != null)
                  Icon(
                    widget.icon,
                    color: widget.isDisabled
                        ? Colors.white.withOpacity(0.5)
                        : Colors.white,
                    size: 28,
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: widget.isDisabled
                              ? Colors.white.withOpacity(0.5)
                              : Colors.white,
                          fontSize: _DS.fontLg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          color: widget.isDisabled
                              ? Colors.white.withOpacity(0.3)
                              : Colors.white.withOpacity(0.75),
                          fontSize: _DS.fontSm,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: widget.isDisabled
                      ? Colors.white.withOpacity(0.5)
                      : Colors.white,
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
