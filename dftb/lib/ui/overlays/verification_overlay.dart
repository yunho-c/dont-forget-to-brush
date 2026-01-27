import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import '../../models/notification_models.dart';
import '../../models/verification_method.dart';
import '../../theme/app_colors.dart';

enum _OverlayStep { alarm, verify, success }

class VerificationOverlay extends StatefulWidget {
  const VerificationOverlay({
    super.key,
    required this.isOpen,
    required this.isAlarmMode,
    required this.method,
    required this.onSuccess,
    required this.onDismiss,
    this.onFailure,
    this.onCancel,
  });

  final bool isOpen;
  final bool isAlarmMode;
  final VerificationMethod method;
  final VoidCallback onSuccess;
  final VoidCallback onDismiss;
  final ValueChanged<VerificationFailureReason>? onFailure;
  final VoidCallback? onCancel;

  @override
  State<VerificationOverlay> createState() => _VerificationOverlayState();
}

class _VerificationOverlayState extends State<VerificationOverlay>
    with SingleTickerProviderStateMixin {
  _OverlayStep _step = _OverlayStep.alarm;
  late final AnimationController _manualController;
  Timer? _scanTimer;
  bool _cameraActive = false;

  @override
  void initState() {
    super.initState();
    _manualController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 2800),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _completeVerification();
          }
        });
  }

  @override
  void didUpdateWidget(covariant VerificationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && !oldWidget.isOpen) {
      _resetForOpen();
    }
  }

  @override
  void dispose() {
    _manualController.dispose();
    _scanTimer?.cancel();
    super.dispose();
  }

  void _resetForOpen() {
    _scanTimer?.cancel();
    _manualController.reset();
    _cameraActive = widget.method == VerificationMethod.selfie;
    _step = widget.isAlarmMode ? _OverlayStep.alarm : _OverlayStep.verify;
    if (_step == _OverlayStep.verify) {
      _startAutoScanIfNeeded();
    }
    setState(() {});
  }

  void _startAutoScanIfNeeded() {
    _scanTimer?.cancel();
    if (widget.method == VerificationMethod.nfc) {
      _scanTimer = Timer(const Duration(milliseconds: 2400), () {
        _completeVerification();
      });
    }
  }

  void _completeVerification() {
    setState(() {
      _step = _OverlayStep.success;
    });
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        widget.onSuccess();
      }
    });
  }

  void _startManualPress() {
    if (_step != _OverlayStep.verify ||
        widget.method != VerificationMethod.manual) {
      return;
    }
    _manualController.forward(from: 0);
  }

  void _endManualPress() {
    if (widget.method != VerificationMethod.manual) return;
    if (_manualController.isAnimating) {
      final progress = _manualController.value;
      _manualController.stop();
      _manualController.reset();
      if (progress > 0 && progress < 1) {
        widget.onFailure?.call(VerificationFailureReason.tooShort);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    if (_step == _OverlayStep.alarm) {
      return _buildAlarmScreen(context);
    }

    final isAlarm = widget.isAlarmMode;
    final background = _step == _OverlayStep.success
        ? AppColors.green500
        : isAlarm
        ? AppColors.red600
        : AppColors.night900;

    return Material(
      color: background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeader(isAlarm),
              Expanded(child: _buildBody()),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmScreen(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          _buildAlarmBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 18 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAlarmTopPill(),
                    const SizedBox(height: 24),
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: _buildAlarmHeroCard(),
                        ),
                      ),
                    ),
                    _buildAlarmPrimaryAction(),
                    const SizedBox(height: 12),
                    _buildAlarmFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.night900,
            Color(0xFF1B2140),
            Color(0xFF3A1C2E),
            AppColors.orange400,
          ],
          stops: [0, 0.35, 0.7, 1],
        ),
      ),
      child: Stack(
        children: [
          _buildGlowOrb(
            alignment: const Alignment(-0.9, -0.8),
            size: 280,
            color: AppColors.orange400,
            intensity: 0.5,
          ),
          _buildGlowOrb(
            alignment: const Alignment(0.9, 0.9),
            size: 360,
            color: AppColors.indigo500,
            intensity: 0.35,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.night950.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowOrb({
    required Alignment alignment,
    required double size,
    required Color color,
    double intensity = 0.5,
  }) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: intensity),
                  color.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmTopPill() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.alarm_rounded, size: 16, color: Colors.white70),
            SizedBox(width: 8),
            Text(
              'Morning check-in',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmHeroCard() {
    IconData methodIcon = Icons.timer_rounded;
    String methodTitle = 'Hold to verify';
    String methodHint = 'Keep pressure steady until it completes.';

    switch (widget.method) {
      case VerificationMethod.manual:
        methodIcon = Icons.timer_rounded;
        methodTitle = 'Hold to verify';
        methodHint = 'Keep pressure steady until it completes.';
        break;
      case VerificationMethod.nfc:
        methodIcon = Icons.nfc;
        methodTitle = 'Tap your tag';
        methodHint = 'Hold your device near the NFC tag.';
        break;
      case VerificationMethod.selfie:
        methodIcon = Icons.camera_alt_outlined;
        methodTitle = 'Take a selfie';
        methodHint = 'Frame your face inside the guide.';
        break;
    }

    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.orange400.withValues(alpha: 0.9),
                    AppColors.red500,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.orange400.withValues(alpha: 0.45),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.wb_sunny_outlined,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Wake up and brush',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'Start the day with a real check-in to protect your streak.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: 18),
            _buildMethodChip(methodIcon, methodTitle),
            const SizedBox(height: 8),
            Text(
              methodHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmPrimaryAction() {
    return InkWell(
      onTap: () {
        setState(() {
          _step = _OverlayStep.verify;
        });
        _startAutoScanIfNeeded();
      },
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.emerald400, Color(0xFF14B8A6)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.emerald400.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "I'm up",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 2),
              Text(
                'Start check-in',
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmFooter() {
    return TextButton(
      onPressed: () {
        widget.onCancel?.call();
        widget.onDismiss();
      },
      style: TextButton.styleFrom(
        foregroundColor: Colors.white.withValues(alpha: 0.75),
      ),
      child: const Text(
        'Skip for now',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.night950.withValues(alpha: 0.45),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isAlarm) {
    if (_step == _OverlayStep.success) {
      return const SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Icon(Icons.check_circle, size: 72, color: AppColors.green500),
            SizedBox(height: 12),
            Text(
              'Tonight Complete!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text(
              'Sleep well.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.slate300),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (isAlarm)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Alarm Active',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        const SizedBox(height: 16),
        const Text(
          'Brush Check',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          "Let's finish the day strong.",
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.slate300),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_step == _OverlayStep.success) {
      return const SizedBox.shrink();
    }

    switch (widget.method) {
      case VerificationMethod.manual:
        return Center(
          child: GestureDetector(
            onTapDown: (_) => _startManualPress(),
            onTapUp: (_) => _endManualPress(),
            onTapCancel: _endManualPress,
            child: AnimatedBuilder(
              animation: _manualController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        value: _manualController.value,
                        strokeWidth: 8,
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.indigo500,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(_manualController.value * 100).floor()}%',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Hold',
                          style: TextStyle(
                            color: AppColors.slate300,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      case VerificationMethod.nfc:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.nfc, size: 96, color: AppColors.indigo500),
            const SizedBox(height: 16),
            const Text('Scanning for tag...'),
            const SizedBox(height: 20),
            shadcn.Button.ghost(
              onPressed: _completeVerification,
              style: const shadcn.ButtonStyle.ghost(
                size: shadcn.ButtonSize.small,
                density: shadcn.ButtonDensity.compact,
              ),
              child: const Text('(Simulate Tap)'),
            ),
          ],
        );
      case VerificationMethod.selfie:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 320,
              width: 240,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white12),
              ),
              child: Stack(
                children: [
                  if (_cameraActive)
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Simulating Camera...',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  else
                    const Center(child: CircularProgressIndicator()),
                  Positioned(
                    left: 24,
                    right: 24,
                    top: 24,
                    bottom: 24,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: Colors.white38),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            shadcn.Button.primary(
              style: const shadcn.ButtonStyle.primary(
                size: shadcn.ButtonSize.normal,
                density: shadcn.ButtonDensity.comfortable,
              ),
              onPressed: _completeVerification,
              child: const Text('Take Photo'),
            ),
          ],
        );
    }
  }

  Widget _buildFooter() {
    if (_step == _OverlayStep.success) {
      return const SizedBox(height: 48);
    }

    if (_step == _OverlayStep.verify && widget.isAlarmMode) {
      return Column(
        children: [
          shadcn.Button.ghost(
            onPressed: () {
              setState(() {
                _step = _OverlayStep.alarm;
              });
              widget.onCancel?.call();
            },
            child: const Text('Cancel'),
          ),
          shadcn.Button.ghost(
            onPressed: () {
              widget.onCancel?.call();
              widget.onDismiss();
            },
            child: const Text('Skip / Emergency Dismiss'),
          ),
        ],
      );
    }

    return shadcn.Button.ghost(
      onPressed: () {
        widget.onCancel?.call();
        widget.onDismiss();
      },
      child: const Text('Skip for now'),
    );
  }
}
