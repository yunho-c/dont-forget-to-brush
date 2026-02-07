import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import '../../models/alarm_tone.dart';
import '../../models/app_mode.dart';
import '../../models/notification_models.dart';
import '../../models/routine_copy.dart';
import '../../models/verification_method.dart';
import '../../state/app_state_provider.dart';
import '../../theme/app_colors.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _profileTapCount = 0;

  void _handleProfileTap() {
    _profileTapCount += 1;
    if (_profileTapCount < 5) {
      return;
    }
    _profileTapCount = 0;
    ref.read(appStateProvider).toggleDeveloperMode();
  }

  Future<_NotificationDebugData> _loadNotificationDebugData({
    bool showAll = false,
  }) async {
    await ref.read(appStateProvider).syncNotificationDeliveries();
    final repo = ref.read(notificationRepositoryProvider);
    final limit = showAll ? null : 8;
    final schedules = await repo.fetchRecentSchedules(limit: limit);
    final attempts = await repo.fetchRecentVerificationAttempts(limit: limit);
    final deliveries = await repo.fetchRecentDeliveryViews(limit: limit);
    return _NotificationDebugData(
      schedules: schedules,
      attempts: attempts,
      deliveries: deliveries,
    );
  }

  void _showNotificationDebugSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.night900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        var showAll = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: FutureBuilder<_NotificationDebugData>(
                future: _loadNotificationDebugData(showAll: showAll),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snapshot.data ?? _NotificationDebugData.empty();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Notification Logs',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Row(
                            children: [
                              shadcn.Button.ghost(
                                style: const shadcn.ButtonStyle.ghost(
                                  size: shadcn.ButtonSize.small,
                                  density: shadcn.ButtonDensity.compact,
                                ),
                                onPressed: () {
                                  setModalState(() {});
                                },
                                child: const Text('Refresh'),
                              ),
                              const SizedBox(width: 8),
                              shadcn.Button.ghost(
                                style: const shadcn.ButtonStyle.ghost(
                                  size: shadcn.ButtonSize.small,
                                  density: shadcn.ButtonDensity.compact,
                                ),
                                onPressed: () {
                                  setModalState(() {
                                    showAll = !showAll;
                                  });
                                },
                                child: Text(showAll ? 'Show less' : 'Show all'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView(
                          children: [
                            _DebugSection(
                              title: 'Scheduled',
                              items:
                                  data.schedules.map(_formatSchedule).toList(),
                              emptyLabel: 'No recent schedules.',
                            ),
                            const SizedBox(height: 16),
                            _DebugSection(
                              title: 'Delivered',
                              items:
                                  data.deliveries.map(_formatDelivery).toList(),
                              emptyLabel: 'No delivery logs yet.',
                            ),
                            const SizedBox(height: 16),
                            _DebugSection(
                              title: 'Verification Attempts',
                              items:
                                  data.attempts.map(_formatAttempt).toList(),
                              emptyLabel: 'No verification attempts yet.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  String _formatSchedule(NotificationSchedule schedule) {
    final typeLabel =
        schedule.type == NotificationScheduleType.alarm ? 'Alarm' : 'Reminder';
    final timeLabel = _formatDateTime(schedule.scheduledAt);
    return '$typeLabel · $timeLabel · ${schedule.status.storageValue}';
  }

  String _formatAttempt(VerificationAttempt attempt) {
    final timeLabel = _formatDateTime(attempt.startedAt);
    final methodLabel = attempt.method.label;
    final resultLabel = attempt.result.storageValue;
    final reason = attempt.failureReason?.storageValue;
    return reason == null
        ? '$methodLabel · $resultLabel · $timeLabel'
        : '$methodLabel · $resultLabel ($reason) · $timeLabel';
  }

  String _formatDelivery(NotificationDeliveryView view) {
    final timeLabel = _formatDateTime(view.delivery.deliveredAt);
    final statusLabel = view.delivery.status.storageValue;
    final typeLabel = switch (view.scheduleType) {
      NotificationScheduleType.alarm => 'Alarm',
      NotificationScheduleType.reminder => 'Reminder',
      _ => 'Unknown',
    };
    return '$typeLabel · $timeLabel · $statusLabel';
  }

  String _formatDateTime(DateTime time) {
    final date =
        '${time.month.toString().padLeft(2, '0')}/${time.day.toString().padLeft(2, '0')}';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$date $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
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
              GestureDetector(
                onTap: _handleProfileTap,
                child: Container(
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
                trailing: _SelectField<AppMode>(
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
          _SectionHeader(title: 'Alarm'),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              _SettingsRow(
                icon: Icons.music_note,
                label: 'Alarm Sound',
                trailing: _SelectField<AlarmTone>(
                  value: settings.alarmTone,
                  items: AlarmTone.values,
                  labelBuilder: (tone) => tone.label,
                  onChanged: (tone) {
                    if (tone != null) {
                      state.updateAlarmTone(tone);
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
                trailing: _SelectField<VerificationMethod>(
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
          if (state.isDeveloperMode) ...[
            const SizedBox(height: 20),
            _SectionHeader(title: 'Developer'),
            const SizedBox(height: 12),
            _SettingsCard(
              children: [
                _SettingsRow(
                  icon: Icons.restart_alt,
                  label: 'Reset App State',
                  value: 'Prototype only',
                  onTap: () => unawaited(state.reset()),
                ),
                const Divider(height: 1, color: AppColors.night700),
                _SettingsRow(
                  icon: Icons.alarm,
                  label: 'Test Alarm',
                  onTap: () => state.openAlarm(),
                ),
                const Divider(height: 1, color: AppColors.night700),
                _SettingsRow(
                  icon: Icons.wb_sunny_outlined,
                  label: 'Routine Phase',
                  trailing: _RoutinePhaseToggle(
                    selected: state.routinePhase,
                    onSelected: (phase) {
                      state.setRoutinePhaseOverride(phase);
                    },
                  ),
                ),
                const Divider(height: 1, color: AppColors.night700),
                _SettingsRow(
                  icon: Icons.notifications,
                  label: 'Test Reminder Notification',
                  value: 'in 10s',
                  onTap: () => unawaited(state.scheduleTestReminder()),
                ),
                const Divider(height: 1, color: AppColors.night700),
                _SettingsRow(
                  icon: Icons.notification_important,
                  label: 'Test Alarm Notification',
                  value: 'in 15s',
                  onTap: () => unawaited(state.scheduleTestAlarm()),
                ),
                const Divider(height: 1, color: AppColors.night700),
                _SettingsRow(
                  icon: Icons.notifications_active,
                  label: 'Show Immediate Notification',
                  onTap: () => unawaited(state.showTestNotification()),
                ),
                const Divider(height: 1, color: AppColors.night700),
                _SettingsRow(
                  icon: Icons.list_alt,
                  label: 'Log Pending Notifications',
                  onTap: () => unawaited(state.logPendingNotifications()),
                ),
                const Divider(height: 1, color: AppColors.night700),
                _SettingsRow(
                  icon: Icons.notifications_off,
                  label: 'Cancel All Notifications',
                  onTap: () => unawaited(state.cancelAllNotifications()),
                ),
                const Divider(height: 1, color: AppColors.night700),
                _SettingsRow(
                  icon: Icons.bug_report,
                  label: 'View Notification Logs',
                  onTap: _showNotificationDebugSheet,
                ),
              ],
            ),
          ],
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

class _DebugSection extends StatelessWidget {
  const _DebugSection({
    required this.title,
    required this.items,
    required this.emptyLabel,
  });

  final String title;
  final List<String> items;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.slate400,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(
            emptyLabel,
            style: const TextStyle(color: AppColors.slate400, fontSize: 12),
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                item,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
      ],
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
      child: Column(
        children: [
          for (final child in children) ...[
            if (child is Divider) const SizedBox(height: 14),
            child,
            if (child is Divider) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

    if (onTap == null) {
      return content;
    }

    return InkWell(onTap: onTap, child: content);
  }
}

class _RoutinePhaseToggle extends StatelessWidget {
  const _RoutinePhaseToggle({
    required this.selected,
    required this.onSelected,
  });

  final RoutinePhase selected;
  final ValueChanged<RoutinePhase> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = RoutinePhase.values;
    return ToggleButtons(
      isSelected: options.map((phase) => phase == selected).toList(),
      onPressed: (index) => onSelected(options[index]),
      borderRadius: BorderRadius.circular(12),
      constraints: const BoxConstraints(minHeight: 32, minWidth: 72),
      color: AppColors.slate400,
      selectedColor: Colors.white,
      fillColor: AppColors.indigo500,
      borderColor: AppColors.night700,
      selectedBorderColor: AppColors.indigo500,
      children: options
          .map(
            (phase) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                phase.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SelectField<T> extends StatelessWidget {
  const _SelectField({
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
    return shadcn.Select<T>(
      value: value,
      onChanged: (value) => onChanged(value),
      filled: true,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      borderRadius: BorderRadius.circular(12),
      popupWidthConstraint: shadcn.PopoverConstraint.intrinsic,
      popupConstraints: const BoxConstraints(minWidth: 110, maxWidth: 320),
      popup: (context) => shadcn.SelectPopup.noVirtualization(
        items: shadcn.SelectItemList(
          children: items
              .map(
                (item) => shadcn.SelectItemButton<T>(
                  value: item,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      labelBuilder(item),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
      itemBuilder: (context, item) => Text(
        labelBuilder(item),
        style: const TextStyle(
          color: AppColors.slate300,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NotificationDebugData {
  const _NotificationDebugData({
    required this.schedules,
    required this.attempts,
    required this.deliveries,
  });

  final List<NotificationSchedule> schedules;
  final List<VerificationAttempt> attempts;
  final List<NotificationDeliveryView> deliveries;

  factory _NotificationDebugData.empty() =>
      const _NotificationDebugData(
        schedules: [],
        attempts: [],
        deliveries: [],
      );
}
