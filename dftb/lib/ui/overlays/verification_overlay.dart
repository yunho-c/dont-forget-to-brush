import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

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
  });

  final bool isOpen;
  final bool isAlarmMode;
  final VerificationMethod method;
  final VoidCallback onSuccess;
  final VoidCallback onDismiss;

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
      _manualController.stop();
      _manualController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

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

    if (_step == _OverlayStep.alarm) {
      return Column(
        children: const [
          Icon(Icons.lock_outline, size: 48, color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Wake Up & Brush',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            "Don't break the streak. Prove you're awake.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate300),
          ),
        ],
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

    if (_step == _OverlayStep.alarm) {
      return Center(
        child: shadcn.Button.primary(
          style: const shadcn.ButtonStyle.primary(
            size: shadcn.ButtonSize.large,
            density: shadcn.ButtonDensity.comfortable,
          ),
          onPressed: () {
            setState(() {
              _step = _OverlayStep.verify;
            });
            _startAutoScanIfNeeded();
          },
          child: const Text("I'm Up, Let's Brush"),
        ),
      );
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
            },
            child: const Text('Cancel'),
          ),
          shadcn.Button.ghost(
            onPressed: widget.onDismiss,
            child: const Text('Skip / Emergency Dismiss'),
          ),
        ],
      );
    }

    return shadcn.Button.ghost(
      onPressed: widget.onDismiss,
      child: const Text('Skip for now'),
    );
  }
}
