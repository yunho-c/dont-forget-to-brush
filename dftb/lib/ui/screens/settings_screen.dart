import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import '../../models/app_mode.dart';
import '../../models/verification_method.dart';
import '../../state/app_state_scope.dart';
import '../../theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final settings = state.settings;
    final initials = _initials(settings.name);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.indigo500,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    settings.name.isEmpty ? 'My Profile' : settings.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Strictness: ${settings.mode.label}',
                    style: const TextStyle(
                      color: AppColors.slate400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Routine'),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              _SettingsRow(
                icon: Icons.alarm,
                label: 'Bedtime Window',
                value: '${settings.bedtimeStart} - ${settings.bedtimeEnd}',
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.slate400,
                ),
              ),
              const Divider(height: 1, color: AppColors.night700),
              _SettingsRow(
                icon: Icons.shield_outlined,
                label: 'Mode',
                trailing: _Dropdown<AppMode>(
                  value: settings.mode,
                  items: AppMode.values,
                  labelBuilder: (mode) => mode.label,
                  onChanged: (mode) {
                    if (mode != null) {
                      state.updateMode(mode);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: 'Verification'),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              _SettingsRow(
                icon: Icons.lock_outline,
                label: 'Method',
                trailing: _Dropdown<VerificationMethod>(
                  value: settings.verificationMethod,
                  items: VerificationMethod.values,
                  labelBuilder: (method) => method.label,
                  onChanged: (method) {
                    if (method != null) {
                      state.updateVerificationMethod(method);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          shadcn.Button.destructive(
            onPressed: state.reset,
            child: const Text('Reset App State (Prototype Only)'),
          ),
          const SizedBox(height: 8),
          Center(
            child: shadcn.Button.ghost(
              onPressed: state.openAlarm,
              style: const shadcn.ButtonStyle.ghost(
                size: shadcn.ButtonSize.small,
                density: shadcn.ButtonDensity.compact,
              ),
              child: const Text('Test Alarm'),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    if (name.isEmpty) return 'ME';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        color: AppColors.slate400,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return shadcn.Card(
      borderRadius: BorderRadius.circular(18),
      borderColor: AppColors.night700,
      fillColor: AppColors.night800,
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.slate400, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (value != null)
            Text(
              value!,
              style: const TextStyle(color: AppColors.slate400, fontSize: 12),
            ),
          if (trailing != null) ...[
            if (value != null) const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<T>(
      value: value,
      onChanged: onChanged,
      dropdownColor: AppColors.night800,
      underline: const SizedBox.shrink(),
      iconEnabledColor: AppColors.slate400,
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                labelBuilder(item),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          )
          .toList(),
    );
  }
}
