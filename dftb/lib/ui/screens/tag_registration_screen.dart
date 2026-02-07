import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import '../../models/tag_models.dart';
import '../../state/app_state_provider.dart';
import '../../theme/app_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/app_buttons.dart';
import '../widgets/step_indicator.dart';

enum _TagRegistrationStep { scan, name, verify }

class TagRegistrationScreen extends ConsumerStatefulWidget {
  const TagRegistrationScreen({super.key, required this.isDeveloperMode});

  final bool isDeveloperMode;

  @override
  ConsumerState<TagRegistrationScreen> createState() =>
      _TagRegistrationScreenState();
}

class _TagRegistrationScreenState extends ConsumerState<TagRegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final Random _random = Random();

  _TagRegistrationStep _step = _TagRegistrationStep.scan;
  TagType _selectedType = TagType.nfc;
  String? _firstCredential;
  bool _scanInFlight = false;
  bool _saveInFlight = false;
  String? _statusLabel;
  String? _errorLabel;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int get _stepNumber {
    switch (_step) {
      case _TagRegistrationStep.scan:
        return 1;
      case _TagRegistrationStep.name:
        return 2;
      case _TagRegistrationStep.verify:
        return 3;
    }
  }

  Future<void> _runScan() async {
    if (_selectedType != TagType.nfc || _scanInFlight) return;

    setState(() {
      _scanInFlight = true;
      _errorLabel = null;
      _statusLabel = 'Waiting for NFC tag...';
    });

    final result = await ref.read(appStateProvider).scanForTag();

    if (!mounted) return;

    setState(() {
      _scanInFlight = false;
      switch (result.status) {
        case NfcScanStatus.found:
          _firstCredential = result.identifier;
          _statusLabel = 'Tag captured: ${formatTagCredential(result.identifier!)}';
          _errorLabel = null;
          _nameController.text = _nameController.text.trim().isEmpty
              ? 'Bathroom Tag'
              : _nameController.text;
          break;
        case NfcScanStatus.timedOut:
        case NfcScanStatus.canceled:
          _statusLabel = null;
          _errorLabel = result.message ?? 'No tag detected.';
          break;
        case NfcScanStatus.unavailable:
        case NfcScanStatus.unsupported:
        case NfcScanStatus.error:
          _statusLabel = null;
          _errorLabel = result.message ?? 'Could not scan this tag.';
          break;
      }
    });
  }

  void _mockScan([String? sample]) {
    final generated = sample ??
        List.generate(8, (_) => _random.nextInt(256))
            .map((value) => value.toRadixString(16).padLeft(2, '0'))
            .join();
    setState(() {
      _firstCredential = generated;
      _statusLabel = 'Debug tag loaded: ${formatTagCredential(generated)}';
      _errorLabel = null;
      _nameController.text = _nameController.text.trim().isEmpty
          ? 'Bathroom Tag'
          : _nameController.text;
    });
  }

  void _next() {
    if (_step == _TagRegistrationStep.scan) {
      if (_selectedType != TagType.nfc || _firstCredential == null) return;
      setState(() {
        _step = _TagRegistrationStep.name;
      });
      return;
    }

    if (_step == _TagRegistrationStep.name) {
      final trimmed = _nameController.text.trim();
      if (trimmed.isEmpty) {
        setState(() {
          _errorLabel = 'Give this tag a short name first.';
        });
        return;
      }
      setState(() {
        _step = _TagRegistrationStep.verify;
        _errorLabel = null;
        _statusLabel = 'Scan the same tag one more time.';
      });
    }
  }

  Future<void> _verifyAndSave() async {
    if (_saveInFlight || _firstCredential == null) return;

    setState(() {
      _saveInFlight = true;
      _errorLabel = null;
      _statusLabel = 'Verifying tag...';
    });

    final result = await ref.read(appStateProvider).scanForTag();

    if (!mounted) return;

    if (result.status != NfcScanStatus.found || result.identifier == null) {
      setState(() {
        _saveInFlight = false;
        _errorLabel = result.message ?? 'Unable to verify tag.';
      });
      return;
    }

    final first = normalizeTagCredential(_firstCredential!);
    final second = normalizeTagCredential(result.identifier!);
    if (first != second) {
      setState(() {
        _saveInFlight = false;
        _errorLabel = 'That was a different tag. Please scan the same one.';
      });
      return;
    }

    await ref.read(appStateProvider).addTag(
          type: _selectedType,
          name: _nameController.text.trim(),
          credential: first,
        );

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _debugCompleteFromCurrentTag() async {
    if (_firstCredential == null) return;
    setState(() {
      _saveInFlight = true;
      _errorLabel = null;
      _statusLabel = 'Debug verification succeeded.';
    });
    await ref.read(appStateProvider).addTag(
          type: _selectedType,
          name: _nameController.text.trim().isEmpty
              ? 'Bathroom Tag'
              : _nameController.text.trim(),
          credential: _firstCredential!,
        );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _step == _TagRegistrationStep.scan
        ? _selectedType == TagType.nfc && _firstCredential != null
        : _step == _TagRegistrationStep.name;

    return shadcn.Scaffold(
      child: AppBackground(
        showLine: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    shadcn.Button.ghost(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Back'),
                    ),
                    const Spacer(),
                  ],
                ),
                StepIndicator(step: _stepNumber, total: 3),
                const SizedBox(height: 18),
                Text(
                  _titleForStep(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _subtitleForStep(),
                  style: const TextStyle(color: AppColors.slate400),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _buildStepBody(),
                  ),
                ),
                if (_errorLabel != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorLabel!,
                    style: const TextStyle(
                      color: AppColors.red500,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else if (_statusLabel != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _statusLabel!,
                    style: const TextStyle(
                      color: AppColors.slate300,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (_step != _TagRegistrationStep.verify)
                  PrimaryButton(
                    label: _step == _TagRegistrationStep.name
                        ? 'Continue'
                        : 'Continue to Name',
                    onPressed: canContinue ? _next : null,
                  )
                else
                  PrimaryButton(
                    label: _saveInFlight ? 'Verifying...' : 'Save Tag',
                    onPressed: _saveInFlight ? null : _verifyAndSave,
                    isLoading: _saveInFlight,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _titleForStep() {
    switch (_step) {
      case _TagRegistrationStep.scan:
        return 'Add a Tag';
      case _TagRegistrationStep.name:
        return 'Name this tag';
      case _TagRegistrationStep.verify:
        return 'Verify scan';
    }
  }

  String _subtitleForStep() {
    switch (_step) {
      case _TagRegistrationStep.scan:
        return 'Scan once to capture it, then we’ll lock it in.';
      case _TagRegistrationStep.name:
        return 'Use a location-based name like Sink or Mirror.';
      case _TagRegistrationStep.verify:
        return 'Scan the same tag again to prevent mistakes.';
    }
  }

  Widget _buildStepBody() {
    switch (_step) {
      case _TagRegistrationStep.scan:
        return Column(
          key: const ValueKey('tag-step-scan'),
          children: [
            Expanded(child: _buildScanStage()),
            const SizedBox(height: 16),
            _buildTypeChooser(),
            if (_selectedType == TagType.nfc) ...[
              const SizedBox(height: 12),
              shadcn.Button.secondary(
                onPressed: _scanInFlight ? null : _runScan,
                child: Text(_scanInFlight ? 'Scanning…' : 'Scan NFC Tag'),
              ),
            ],
            if (widget.isDeveloperMode) ...[
              const SizedBox(height: 12),
              _DebugCard(
                title: 'Developer shortcuts',
                children: [
                  _DebugButton(
                    label: 'Mock NFC Read',
                    onPressed: _selectedType == TagType.nfc ? _mockScan : null,
                  ),
                  _DebugButton(
                    label: 'Load Sample A',
                    onPressed: _selectedType == TagType.nfc
                        ? () => _mockScan('04a2b4d91f662280')
                        : null,
                  ),
                ],
              ),
            ],
          ],
        );
      case _TagRegistrationStep.name:
        return Column(
          key: const ValueKey('tag-step-name'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoCard(
              icon: Icons.sell_outlined,
              title: 'Captured ID',
              body: formatTagCredential(_firstCredential ?? ''),
            ),
            const SizedBox(height: 16),
            shadcn.TextField(
              controller: _nameController,
              hintText: 'Bathroom Sink',
            ),
            const SizedBox(height: 10),
            const Text(
              'Tip: choose a physical location name you’ll recognize instantly.',
              style: TextStyle(color: AppColors.slate400, fontSize: 12),
            ),
          ],
        );
      case _TagRegistrationStep.verify:
        return Column(
          key: const ValueKey('tag-step-verify'),
          children: [
            Expanded(child: _buildVerifyStage()),
            const SizedBox(height: 12),
            _InfoCard(
              icon: Icons.check_circle_outline,
              title: 'Expected ID',
              body: formatTagCredential(_firstCredential ?? ''),
            ),
            if (widget.isDeveloperMode) ...[
              const SizedBox(height: 12),
              _DebugCard(
                title: 'Developer shortcuts',
                children: [
                  _DebugButton(
                    label: 'Mock Matching Scan',
                    onPressed: _saveInFlight ? null : _debugCompleteFromCurrentTag,
                  ),
                  _DebugButton(
                    label: 'Mock Wrong Scan',
                    onPressed: _saveInFlight
                        ? null
                        : () {
                            setState(() {
                              _errorLabel =
                                  'Debug: wrong tag detected. Try scanning again.';
                              _statusLabel = null;
                            });
                          },
                  ),
                ],
              ),
            ],
          ],
        );
    }
  }

  Widget _buildScanStage() {
    return _ScanStageCard(
      title: _selectedType == TagType.nfc ? 'NFC Scanner' : 'QR Camera',
      subtitle: _selectedType == TagType.nfc
          ? (_firstCredential == null
              ? 'Hold your phone close to the bathroom tag.'
              : 'Tag captured successfully.')
          : 'QR mode is coming soon.',
      icon: _selectedType == TagType.nfc ? Icons.nfc : Icons.qr_code_scanner,
      state: _selectedType == TagType.nfc
          ? (_firstCredential == null
              ? (_scanInFlight ? _ScanStageState.active : _ScanStageState.idle)
              : _ScanStageState.success)
          : _ScanStageState.comingSoon,
    );
  }

  Widget _buildVerifyStage() {
    return _ScanStageCard(
      title: 'Re-scan for verification',
      subtitle: 'Use the exact same tag to confirm registration.',
      icon: Icons.verified_user_outlined,
      state: _saveInFlight ? _ScanStageState.active : _ScanStageState.idle,
    );
  }

  Widget _buildTypeChooser() {
    return shadcn.Card(
      borderRadius: BorderRadius.circular(16),
      borderColor: AppColors.night700,
      fillColor: AppColors.night800,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: _TagTypeCard(
              label: 'NFC',
              caption: 'Available now',
              icon: Icons.nfc,
              selected: _selectedType == TagType.nfc,
              onTap: () {
                setState(() {
                  _selectedType = TagType.nfc;
                  _errorLabel = null;
                });
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _TagTypeCard(
              label: 'QR',
              caption: 'Coming soon',
              icon: Icons.qr_code_2,
              selected: _selectedType == TagType.qr,
              onTap: () {
                setState(() {
                  _selectedType = TagType.qr;
                  _errorLabel = 'QR registration is not available yet.';
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum _ScanStageState { idle, active, success, comingSoon }

class _ScanStageCard extends StatelessWidget {
  const _ScanStageCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.state,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final _ScanStageState state;

  @override
  Widget build(BuildContext context) {
    final accent = switch (state) {
      _ScanStageState.idle => AppColors.indigo500,
      _ScanStageState.active => AppColors.orange400,
      _ScanStageState.success => AppColors.emerald400,
      _ScanStageState.comingSoon => AppColors.slate400,
    };

    return shadcn.Card(
      borderRadius: BorderRadius.circular(20),
      borderColor: AppColors.night700,
      fillColor: AppColors.night800.withValues(alpha: 0.75),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accent.withValues(alpha: 0.38),
                  AppColors.night900,
                ],
              ),
              border: Border.all(color: accent.withValues(alpha: 0.5)),
            ),
            child: state == _ScanStageState.active
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(strokeWidth: 2.6),
                  )
                : Icon(
                    state == _ScanStageState.success
                        ? Icons.check_rounded
                        : icon,
                    color: Colors.white,
                    size: 40,
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.slate300, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _TagTypeCard extends StatelessWidget {
  const _TagTypeCard({
    required this.label,
    required this.caption,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String caption;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.indigo500 : AppColors.night700,
          ),
          color: selected
              ? AppColors.indigo500.withValues(alpha: 0.16)
              : AppColors.night900.withValues(alpha: 0.5),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.indigo500 : AppColors.slate400,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              caption,
              style: const TextStyle(fontSize: 11, color: AppColors.slate400),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return shadcn.Card(
      borderRadius: BorderRadius.circular(16),
      borderColor: AppColors.night700,
      fillColor: AppColors.night800,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.slate400),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.1,
                    color: AppColors.slate400,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate200,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DebugCard extends StatelessWidget {
  const _DebugCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return shadcn.Card(
      borderRadius: BorderRadius.circular(14),
      borderColor: AppColors.night700,
      fillColor: AppColors.night800,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: AppColors.slate400,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: children),
        ],
      ),
    );
  }
}

class _DebugButton extends StatelessWidget {
  const _DebugButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return shadcn.Button.ghost(
      onPressed: onPressed,
      style: const shadcn.ButtonStyle.ghost(
        size: shadcn.ButtonSize.small,
        density: shadcn.ButtonDensity.compact,
      ),
      child: Text(label),
    );
  }
}
