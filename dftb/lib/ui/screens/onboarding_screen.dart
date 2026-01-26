import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import '../../models/app_mode.dart';
import '../../models/verification_method.dart';
import '../../state/app_state_provider.dart';
import '../../theme/app_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/app_buttons.dart';
import '../widgets/option_card.dart';
import '../widgets/step_indicator.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _totalSteps = 4;

  int _step = 1;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bedtimeController = TextEditingController(
    text: '22:00',
  );
  AppMode _mode = AppMode.accountability;
  VerificationMethod _method = VerificationMethod.manual;

  @override
  void dispose() {
    _nameController.dispose();
    _bedtimeController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < _totalSteps) {
      setState(() {
        _step += 1;
      });
    } else {
      ref
          .read(appStateProvider)
          .completeOnboarding(
            name: _nameController.text.trim(),
            bedtimeStart: _bedtimeController.text,
            mode: _mode,
            method: _method,
          );
    }
  }

  Future<void> _pickTime() async {
    final current =
        _parseTime(_bedtimeController.text) ??
        const shadcn.TimeOfDay(hour: 22, minute: 0);
    shadcn.TimeOfDay? stagedValue = current;
    final picked = await shadcn.showDialog<shadcn.TimeOfDay>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) {
        return shadcn.AlertDialog(
          title: const Text('Set Bedtime'),
          content: shadcn.TimePickerDialog(
            initialValue: current,
            use24HourFormat: true,
            onChanged: (value) => stagedValue = value,
          ),
          actions: [
            shadcn.Button.ghost(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            shadcn.Button.primary(
              onPressed: () => Navigator.of(context).pop(stagedValue),
              child: const Text('Set'),
            ),
          ],
        );
      },
    );
    if (picked != null) {
      setState(() {
        _bedtimeController.text = _formatTime(picked);
      });
    }
  }

  shadcn.TimeOfDay? _parseTime(String input) {
    final parts = input.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return shadcn.TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(shadcn.TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StepIndicator(step: _step, total: _totalSteps),
                const SizedBox(height: 24),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildStep(context),
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: _step == _totalSteps ? 'Get Started' : 'Next',
                  onPressed: _next,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    switch (_step) {
      case 1:
        return _buildNameStep();
      case 2:
        return _buildBedtimeStep();
      case 3:
        return _buildModeStep();
      case 4:
        return _buildMethodStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNameStep() {
    return Column(
      key: const ValueKey('name-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Let's set you up.",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'First, what should we call you?',
          style: TextStyle(color: AppColors.slate400),
        ),
        const SizedBox(height: 24),
        shadcn.TextField(controller: _nameController, hintText: 'Your name'),
      ],
    );
  }

  Widget _buildBedtimeStep() {
    return Column(
      key: const ValueKey('bedtime-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'When do you sleep?',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          "We'll monitor this window.",
          style: TextStyle(color: AppColors.slate400),
        ),
        const SizedBox(height: 24),
        InkWell(
          onTap: _pickTime,
          borderRadius: BorderRadius.circular(16),
          child: shadcn.Card(
            padding: const EdgeInsets.all(20),
            borderRadius: BorderRadius.circular(16),
            borderColor: AppColors.night700,
            fillColor: AppColors.night800,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Usually in bed by',
                  style: TextStyle(
                    color: AppColors.slate400,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _bedtimeController.text,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeStep() {
    return Column(
      key: const ValueKey('mode-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How strict?',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose your accountability level.',
          style: TextStyle(color: AppColors.slate400),
        ),
        const SizedBox(height: 24),
        OptionCard(
          title: 'Gentle',
          subtitle: 'Reminders only. No alarms.',
          icon: Icons.notifications_none,
          isSelected: _mode == AppMode.gentle,
          onTap: () => setState(() => _mode = AppMode.gentle),
        ),
        const SizedBox(height: 12),
        OptionCard(
          title: 'Accountability',
          subtitle: 'Persistent reminders with snooze.',
          icon: Icons.shield_outlined,
          isSelected: _mode == AppMode.accountability,
          onTap: () => setState(() => _mode = AppMode.accountability),
        ),
        const SizedBox(height: 12),
        OptionCard(
          title: 'No Excuses',
          subtitle: 'Full alarm. Hard verification required.',
          icon: Icons.flash_on,
          isSelected: _mode == AppMode.noExcuses,
          onTap: () => setState(() => _mode = AppMode.noExcuses),
        ),
      ],
    );
  }

  Widget _buildMethodStep() {
    return Column(
      key: const ValueKey('method-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Proof method',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          "How will you prove you're up?",
          style: TextStyle(color: AppColors.slate400),
        ),
        const SizedBox(height: 24),
        OptionCard(
          title: 'Manual Press',
          subtitle: 'Press & hold for 3 seconds.',
          icon: Icons.pan_tool_outlined,
          isSelected: _method == VerificationMethod.manual,
          onTap: () => setState(() => _method = VerificationMethod.manual),
        ),
        const SizedBox(height: 12),
        OptionCard(
          title: 'NFC Tag',
          subtitle: 'Scan a tag in your bathroom.',
          icon: Icons.nfc,
          isSelected: _method == VerificationMethod.nfc,
          onTap: () => setState(() => _method = VerificationMethod.nfc),
        ),
        const SizedBox(height: 12),
        OptionCard(
          title: 'Selfie Check',
          subtitle: 'Quick photo proof.',
          icon: Icons.camera_alt_outlined,
          isSelected: _method == VerificationMethod.selfie,
          onTap: () => setState(() => _method = VerificationMethod.selfie),
        ),
      ],
    );
  }
}
