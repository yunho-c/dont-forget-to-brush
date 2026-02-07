import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import '../../models/alarm_tone.dart';
import '../../models/notification_models.dart';
import '../../models/routine_copy.dart';
import '../../models/tag_models.dart';
import '../../models/verification_method.dart';
import '../../theme/app_colors.dart';

enum _OverlayStep { alarm, verify, success }

class VerificationOverlay extends StatefulWidget {
  const VerificationOverlay({
    super.key,
    required this.isOpen,
    required this.isAlarmMode,
    required this.routinePhase,
    required this.method,
    required this.alarmTone,
    this.supportsSnooze = false,
    this.canSnooze = false,
    this.snoozeLabel,
    this.isDeveloperMode = false,
    this.activeTags = const [],
    required this.onSuccess,
    required this.onDismiss,
    this.onSnooze,
    this.onTagScan,
    this.onDebugMatchTag,
    this.onDebugWrongTag,
    this.onFailure,
    this.onCancel,
  });

  final bool isOpen;
  final bool isAlarmMode;
  final RoutinePhase routinePhase;
  final VerificationMethod method;
  final AlarmTone alarmTone;
  final bool supportsSnooze;
  final bool canSnooze;
  final String? snoozeLabel;
  final bool isDeveloperMode;
  final List<SavedTag> activeTags;
  final VoidCallback onSuccess;
  final VoidCallback onDismiss;
  final VoidCallback? onSnooze;
  final Future<TagVerificationResult> Function()? onTagScan;
  final Future<TagVerificationResult> Function(String? tagId)? onDebugMatchTag;
  final TagVerificationResult Function()? onDebugWrongTag;
  final ValueChanged<VerificationFailureReason>? onFailure;
  final VoidCallback? onCancel;

  @override
  State<VerificationOverlay> createState() => _VerificationOverlayState();
}

class _VerificationOverlayState extends State<VerificationOverlay>
    with SingleTickerProviderStateMixin {
  _OverlayStep _step = _OverlayStep.alarm;
  late final AnimationController _manualController;
  late final SoLoud _soloud;
  bool _cameraActive = false;
  bool _isClosing = false;
  bool _isTagScanInFlight = false;
  String? _tagStatusLabel;
  bool _alarmSoundActive = false;
  AlarmTone? _alarmSoundTone;
  AudioSource? _alarmSource;
  SoundHandle? _alarmHandle;
  int _alarmSessionToken = 0;
  Future<void>? _soloudInitFuture;

  RoutineCopy get _routineCopy => RoutineCopy.forPhase(widget.routinePhase);

  @override
  void initState() {
    super.initState();
    _soloud = SoLoud.instance;
    _manualController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 2800),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _completeVerification();
          }
        });
    _syncAlarmSound();
  }

  @override
  void didUpdateWidget(covariant VerificationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && !oldWidget.isOpen) {
      _resetForOpen();
    }
    if (widget.isOpen != oldWidget.isOpen ||
        widget.isAlarmMode != oldWidget.isAlarmMode ||
        widget.alarmTone != oldWidget.alarmTone) {
      _syncAlarmSound();
    }
  }

  @override
  void dispose() {
    _manualController.dispose();
    _stopAlarmSound();
    _disposeAlarmSource();
    super.dispose();
  }

  void _resetForOpen() {
    _manualController.reset();
    _cameraActive = widget.method == VerificationMethod.selfie;
    _isClosing = false;
    _isTagScanInFlight = false;
    _tagStatusLabel = null;
    _step = widget.isAlarmMode ? _OverlayStep.alarm : _OverlayStep.verify;
    if (_step == _OverlayStep.verify) {
      _startAutoScanIfNeeded();
    }
    _syncAlarmSound();
    setState(() {});
  }

  void _syncAlarmSound() {
    final shouldPlay = widget.isOpen && widget.isAlarmMode;
    if (!shouldPlay) {
      _stopAlarmSound();
      return;
    }
    if (!_alarmSoundActive || _alarmSoundTone != widget.alarmTone) {
      unawaited(_startAlarmSound(widget.alarmTone));
    }
  }

  Future<void> _startAlarmSound(AlarmTone tone) async {
    final token = ++_alarmSessionToken;
    final sessionReady = await _ensureAudioSessionActive();
    if (!sessionReady) return;
    final ready = await _ensureSoloud();
    if (!ready) return;
    final previousTone = _alarmSoundTone;
    _alarmSoundActive = true;
    await _stopAlarmSoundInternal(deactivate: false);
    if (token != _alarmSessionToken) return;
    if (_alarmSource == null || previousTone != tone) {
      await _disposeAlarmSource();
      try {
        _alarmSource = await _soloud.loadAsset(tone.assetPath);
      } on SoLoudTemporaryFolderFailedException {
        final reinit = await _ensureSoloud(force: true);
        if (!reinit) return;
        _alarmSource = await _soloud.loadAsset(tone.assetPath);
      }
    }
    _alarmSoundTone = tone;
    _alarmHandle = await _soloud.play(
      _alarmSource!,
      looping: true,
      volume: 1.0,
    );
  }

  void _stopAlarmSound() {
    if (!_alarmSoundActive) return;
    _alarmSoundActive = false;
    final token = ++_alarmSessionToken;
    unawaited(_stopAlarmSoundInternal(deactivate: true, token: token));
  }

  Future<void> _stopAlarmSoundInternal({
    required bool deactivate,
    int? token,
  }) async {
    if (!_soloud.isInitialized) return;
    final handle = _alarmHandle;
    if (handle != null) {
      _alarmHandle = null;
      try {
        await _soloud.stop(handle);
      } catch (_) {}
    }
    if (!deactivate) return;
    if (token != null && token != _alarmSessionToken) return;
    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (_) {}
    if (Platform.isIOS) {
      // iOS workaround: deactivating the audio session can leave SoLoud's
      // temp loader uninitialized on re-entry, so force a clean init next time.
      _soloud.deinit();
      _alarmSource = null;
      _alarmSoundTone = null;
    }
  }

  Future<void> _disposeAlarmSource() async {
    final source = _alarmSource;
    _alarmSource = null;
    if (source == null) return;
    if (!_soloud.isInitialized) return;
    try {
      await _soloud.disposeSource(source);
    } catch (_) {}
  }

  Future<bool> _ensureSoloud({bool force = false}) async {
    if (!force && _soloud.isInitialized) return true;
    if (_soloudInitFuture != null) {
      try {
        await _soloudInitFuture;
      } catch (_) {}
      return _soloud.isInitialized;
    }
    final completer = Completer<void>();
    _soloudInitFuture = completer.future;
    try {
      await _soloud.init();
      completer.complete();
    } catch (error) {
      completer.completeError(error);
      return false;
    } finally {
      _soloudInitFuture = null;
    }
    return _soloud.isInitialized;
  }

  Future<bool> _ensureAudioSessionActive() async {
    try {
      final session = await AudioSession.instance;
      return await session.setActive(true);
    } catch (_) {
      return false;
    }
  }

  void _startAutoScanIfNeeded() {
    if (widget.method == VerificationMethod.nfc) {
      unawaited(_runTagScan());
    }
  }

  Future<void> _runTagScan() async {
    if (_isTagScanInFlight || widget.onTagScan == null) return;
    setState(() {
      _isTagScanInFlight = true;
      _tagStatusLabel = _routineCopy.methods.nfcVerify.verifyScanningLabel;
    });

    final result = await widget.onTagScan!.call();
    if (!mounted) return;
    _isTagScanInFlight = false;
    _consumeTagVerificationResult(result);
  }

  Future<void> _runDebugMatchTag([String? tagId]) async {
    if (_isTagScanInFlight || widget.onDebugMatchTag == null) return;
    setState(() {
      _isTagScanInFlight = true;
      _tagStatusLabel = 'Running debug match...';
    });
    final result = await widget.onDebugMatchTag!.call(tagId);
    if (!mounted) return;
    _isTagScanInFlight = false;
    _consumeTagVerificationResult(result);
  }

  void _runDebugWrongTag() {
    final result =
        widget.onDebugWrongTag?.call() ?? TagVerificationResult.unrecognized();
    _consumeTagVerificationResult(result);
  }

  void _consumeTagVerificationResult(TagVerificationResult result) {
    if (result.isMatched) {
      _tagStatusLabel = result.message;
      _completeVerification();
      return;
    }

    _tagStatusLabel = result.message;
    if (result.failureReason != null) {
      widget.onFailure?.call(result.failureReason!);
    }
    setState(() {});
  }

  void _completeVerification() {
    _stopAlarmSound();
    _alarmSoundTone = null;
    setState(() {
      _step = _OverlayStep.success;
      _isClosing = false;
    });
    Future<void>.delayed(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      setState(() {
        _isClosing = true;
      });
    });
    Future<void>.delayed(const Duration(milliseconds: 2300), () {
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

    if (_step == _OverlayStep.success) {
      return _buildSuccessScreen(context);
    }

    final isAlarm = widget.isAlarmMode;
    final background =
        _step == _OverlayStep.success ? AppColors.green500 : AppColors.night900;

    if (isAlarm && _step != _OverlayStep.success) {
      return Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            _buildAlarmBackground(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
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
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
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
        ),
      ),
    );
  }

  Widget _buildSuccessScreen(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 380),
      opacity: _isClosing ? 0 : 1,
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            _buildSuccessBackground(),
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
                        offset: Offset(0, 16 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildSuccessHero(),
                                const SizedBox(height: 24),
                                Text(
                                  _routineCopy.success.title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _routineCopy.success.subtitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.4,
                                    color:
                                        Colors.white.withValues(alpha: 0.78),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessBackground() {
    final isNight = widget.routinePhase == RoutinePhase.night;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isNight
          ? const [
              Color(0xFF071421),
              Color(0xFF0B2535),
              Color(0xFF0F3A46),
              Color(0xFF13604F),
            ]
          : const [
              Color(0xFF052821),
              Color(0xFF0C4A3C),
              Color(0xFF0E6B50),
              Color(0xFF1DAA6D),
            ],
      stops: const [0, 0.4, 0.7, 1],
    );

    final primaryOrbColor =
        isNight ? const Color(0xFF2EC4B6) : AppColors.emerald400;
    final secondaryOrbColor =
        isNight ? AppColors.indigo500 : const Color(0xFF22D3EE);

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          _buildGlowOrb(
            alignment: const Alignment(-0.8, -0.75),
            size: 260,
            color: primaryOrbColor,
            intensity: 0.45,
          ),
          _buildGlowOrb(
            alignment: const Alignment(0.9, 0.8),
            size: 340,
            color: secondaryOrbColor,
            intensity: 0.35,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessHero() {
    final isNight = widget.routinePhase == RoutinePhase.night;
    final glowColor =
        isNight ? const Color(0xFF5EEAD4) : const Color(0xFF86FCD5);
    final coreGradient = isNight
        ? const [Color(0xFF1AAE8D), Color(0xFF2DD4BF)]
        : const [Color(0xFF22C55E), Color(0xFF34D399)];

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 190,
          height: 190,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                glowColor.withValues(alpha: 0.35),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.5,
            ),
          ),
        ),
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: coreGradient,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.45),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 52,
          ),
        ),
      ],
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
    final isNight = widget.routinePhase == RoutinePhase.night;
    final primaryOrbColor =
        isNight ? AppColors.indigo500 : AppColors.orange400;
    final secondaryOrbColor =
        isNight ? AppColors.emerald400 : AppColors.indigo500;
    final primaryIntensity = isNight ? 0.45 : 0.5;
    final secondaryIntensity = isNight ? 0.4 : 0.35;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isNight
          ? const [
              Color(0xFF0B1026),
              Color(0xFF101B3D),
              Color(0xFF1F1B4A),
              Color(0xFF0E3A4C),
            ]
          : const [
              AppColors.night900,
              Color(0xFF1B2140),
              Color(0xFF3A1C2E),
              AppColors.orange400,
            ],
      stops: const [0, 0.35, 0.7, 1],
    );

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          _buildGlowOrb(
            alignment: const Alignment(-0.9, -0.8),
            size: 280,
            color: primaryOrbColor,
            intensity: primaryIntensity,
          ),
          _buildGlowOrb(
            alignment: const Alignment(0.9, 0.9),
            size: 360,
            color: secondaryOrbColor,
            intensity: secondaryIntensity,
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
          children: [
            const Icon(Icons.alarm_rounded, size: 16, color: Colors.white70),
            const SizedBox(width: 8),
            Text(
              _routineCopy.alarm.pill,
              style: const TextStyle(
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
    final heroIcon = widget.routinePhase == RoutinePhase.night
        ? Icons.nightlight_round
        : Icons.wb_sunny_outlined;

    final isNight = widget.routinePhase == RoutinePhase.night;
    final heroGradient = isNight
        ? const [AppColors.indigo500, Color(0xFF0F766E)]
        : const [AppColors.orange400, AppColors.red500];
    final heroGlow =
        isNight ? AppColors.indigo500 : AppColors.orange400;

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
                  colors: heroGradient,
                ),
                boxShadow: [
                  BoxShadow(
                    color: heroGlow.withValues(alpha: 0.45),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(heroIcon, color: Colors.white, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              _routineCopy.alarm.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              _routineCopy.alarm.body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: 18),
            _buildAlarmPrimaryAction(heroIcon),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmPrimaryAction(IconData icon) {
    return Center(
      child: InkWell(
        onTap: () {
          setState(() {
            _step = _OverlayStep.verify;
          });
          _startAutoScanIfNeeded();
        },
        borderRadius: BorderRadius.circular(999),
        child: _buildAlarmPill(icon, _routineCopy.alarm.ctaTitle),
      ),
    );
  }

  Widget _buildAlarmFooter() {
    final snoozeLabel = widget.snoozeLabel ?? 'Snooze';
    return Column(
      children: [
        if (widget.supportsSnooze) ...[
          shadcn.Button.ghost(
            onPressed: widget.canSnooze
                ? () {
                    _stopAlarmSound();
                    widget.onSnooze?.call();
                  }
                : null,
            child: Text(snoozeLabel),
          ),
          const SizedBox(height: 8),
        ],
        TextButton(
          onPressed: () {
            _stopAlarmSound();
            widget.onCancel?.call();
            widget.onDismiss();
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white.withValues(alpha: 0.75),
          ),
          child: Text(
            _routineCopy.alarm.skipLabel,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
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
      return SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            const Icon(
              Icons.check_circle,
              size: 72,
              color: AppColors.green500,
            ),
            const SizedBox(height: 12),
            Text(
              _routineCopy.success.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              _routineCopy.success.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.slate300),
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
            child: Text(
              _routineCopy.verify.alarmBadge,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          _routineCopy.verify.title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          _routineCopy.verify.subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.slate300),
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
                        Text(
                          _routineCopy.methods.manualVerify.verifyHoldLabel,
                          style: const TextStyle(
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
        return LayoutBuilder(
          builder: (context, constraints) {
            final panelWidth = constraints.maxWidth < 380
                ? constraints.maxWidth
                : 380.0;
            return Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: panelWidth),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 132,
                      height: 132,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.indigo500.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        gradient: RadialGradient(
                          colors: [
                            AppColors.indigo500.withValues(alpha: 0.32),
                            AppColors.night900.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                      child: _isTagScanInFlight
                          ? const Padding(
                              padding: EdgeInsets.all(38),
                              child: CircularProgressIndicator(strokeWidth: 2.8),
                            )
                          : const Icon(
                              Icons.nfc,
                              size: 64,
                              color: AppColors.indigo500,
                            ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _tagStatusLabel ??
                          _routineCopy.methods.nfcVerify.verifyScanningLabel,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    shadcn.Button.secondary(
                      onPressed: _isTagScanInFlight ? null : _runTagScan,
                      style: const shadcn.ButtonStyle.secondary(
                        size: shadcn.ButtonSize.small,
                        density: shadcn.ButtonDensity.compact,
                      ),
                      child: Text(
                        _isTagScanInFlight
                            ? 'Scanning...'
                            : _routineCopy.methods.nfcVerify.verifySimulateLabel,
                      ),
                    ),
                    if (widget.activeTags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Registered tags: ${widget.activeTags.length}',
                        style: const TextStyle(
                          color: AppColors.slate400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (widget.isDeveloperMode) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: _buildGlassCard(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Developer Debug',
                                  style: TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 1.1,
                                    color: AppColors.slate400,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    shadcn.Button.ghost(
                                      onPressed: _isTagScanInFlight
                                          ? null
                                          : () => unawaited(_runDebugMatchTag()),
                                      style: const shadcn.ButtonStyle.ghost(
                                        size: shadcn.ButtonSize.small,
                                        density: shadcn.ButtonDensity.compact,
                                      ),
                                      child: const Text('Mock Match'),
                                    ),
                                    shadcn.Button.ghost(
                                      onPressed: _isTagScanInFlight
                                          ? null
                                          : _runDebugWrongTag,
                                      style: const shadcn.ButtonStyle.ghost(
                                        size: shadcn.ButtonSize.small,
                                        density: shadcn.ButtonDensity.compact,
                                      ),
                                      child: const Text('Mock Wrong Tag'),
                                    ),
                                    for (final tag in widget.activeTags.take(2))
                                      shadcn.Button.ghost(
                                        onPressed: _isTagScanInFlight
                                            ? null
                                            : () => unawaited(
                                                _runDebugMatchTag(tag.id),
                                              ),
                                        style: const shadcn.ButtonStyle.ghost(
                                          size: shadcn.ButtonSize.small,
                                          density: shadcn.ButtonDensity.compact,
                                        ),
                                        child: Text('Use ${tag.name}'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
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
                        _routineCopy.methods.selfieVerify.verifyCameraLabel,
                        style: const TextStyle(color: Colors.white54),
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
              child: Text(_routineCopy.methods.selfieVerify.verifyCaptureLabel),
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
          if (widget.supportsSnooze) ...[
            shadcn.Button.ghost(
              onPressed: widget.canSnooze
                  ? () {
                      _stopAlarmSound();
                      widget.onSnooze?.call();
                    }
                  : null,
              child: Text(widget.snoozeLabel ?? 'Snooze'),
            ),
            const SizedBox(height: 6),
          ],
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
              _stopAlarmSound();
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
      child: Text(_routineCopy.alarm.skipLabel),
    );
  }
}
