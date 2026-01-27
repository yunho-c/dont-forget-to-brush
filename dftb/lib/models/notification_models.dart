import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'app_mode.dart';
import 'verification_method.dart';

const _uuid = Uuid();

enum NotificationScheduleType { reminder, alarm }

extension NotificationScheduleTypeX on NotificationScheduleType {
  String get storageValue => name;

  static NotificationScheduleType fromStorage(String? value) {
    return NotificationScheduleType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => NotificationScheduleType.reminder,
    );
  }
}

enum NotificationScheduleStatus { scheduled, delivered, canceled, expired }

extension NotificationScheduleStatusX on NotificationScheduleStatus {
  String get storageValue => name;

  static NotificationScheduleStatus fromStorage(String? value) {
    return NotificationScheduleStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => NotificationScheduleStatus.scheduled,
    );
  }
}

enum NotificationDeliveryStatus { delivered, failed, unknown }

extension NotificationDeliveryStatusX on NotificationDeliveryStatus {
  String get storageValue => name;

  static NotificationDeliveryStatus fromStorage(String? value) {
    return NotificationDeliveryStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => NotificationDeliveryStatus.unknown,
    );
  }
}

enum VerificationResult { success, failure, canceled }

extension VerificationResultX on VerificationResult {
  String get storageValue => name;

  static VerificationResult fromStorage(String? value) {
    return VerificationResult.values.firstWhere(
      (result) => result.name == value,
      orElse: () => VerificationResult.failure,
    );
  }
}

enum VerificationFailureReason {
  tooShort,
  noTag,
  wrongTag,
  noFace,
  tooDark,
  timeout,
  permissionDenied,
  other,
}

extension VerificationFailureReasonX on VerificationFailureReason {
  String get storageValue => name;

  static VerificationFailureReason? fromStorage(String? value) {
    if (value == null) return null;
    return VerificationFailureReason.values.firstWhere(
      (reason) => reason.name == value,
      orElse: () => VerificationFailureReason.other,
    );
  }
}

enum AlarmStatus { armed, ringing, snoozed, cleared, expired }

extension AlarmStatusX on AlarmStatus {
  String get storageValue => name;

  static AlarmStatus fromStorage(String? value) {
    return AlarmStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => AlarmStatus.armed,
    );
  }
}

class BedtimeWindow {
  BedtimeWindow({
    String? id,
    required DateTime date,
    required this.startAt,
    required this.endAt,
    required this.mode,
    DateTime? createdAt,
  }) : id = id ?? _uuid.v4(),
       date = _dateOnly(date),
       createdAt = createdAt ?? DateTime.now();

  final String id;
  final DateTime date;
  final DateTime startAt;
  final DateTime endAt;
  final AppMode mode;
  final DateTime createdAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': _dateKey(date),
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
      'mode': mode.storageValue,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static BedtimeWindow fromMap(Map<String, Object?> map) {
    return BedtimeWindow(
      id: map['id'] as String?,
      date: _dateFromKey(map['date'] as String?),
      startAt: DateTime.parse(map['start_at'] as String),
      endAt: DateTime.parse(map['end_at'] as String),
      mode: AppModeX.fromStorage(map['mode'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class NotificationSchedule {
  NotificationSchedule({
    String? id,
    required this.windowId,
    required this.type,
    required this.scheduledAt,
    required this.status,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
  }) : id = id ?? _uuid.v4(),
       payload = payload == null ? null : Map<String, dynamic>.from(payload),
       createdAt = createdAt ?? DateTime.now();

  final String id;
  final String windowId;
  final NotificationScheduleType type;
  final DateTime scheduledAt;
  final NotificationScheduleStatus status;
  final Map<String, dynamic>? payload;
  final DateTime createdAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'window_id': windowId,
      'type': type.storageValue,
      'scheduled_at': scheduledAt.toIso8601String(),
      'payload': payload == null ? null : jsonEncode(payload),
      'status': status.storageValue,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static NotificationSchedule fromMap(Map<String, Object?> map) {
    final payloadRaw = map['payload'] as String?;
    return NotificationSchedule(
      id: map['id'] as String?,
      windowId: map['window_id'] as String,
      type: NotificationScheduleTypeX.fromStorage(map['type'] as String?),
      scheduledAt: DateTime.parse(map['scheduled_at'] as String),
      status: NotificationScheduleStatusX.fromStorage(map['status'] as String?),
      payload: payloadRaw == null
          ? null
          : jsonDecode(payloadRaw) as Map<String, dynamic>,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class NotificationDelivery {
  NotificationDelivery({
    String? id,
    required this.scheduleId,
    required this.deliveredAt,
    required this.status,
    this.platformId,
    DateTime? createdAt,
  }) : id = id ?? _uuid.v4(),
       createdAt = createdAt ?? DateTime.now();

  final String id;
  final String scheduleId;
  final DateTime deliveredAt;
  final NotificationDeliveryStatus status;
  final String? platformId;
  final DateTime createdAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'schedule_id': scheduleId,
      'delivered_at': deliveredAt.toIso8601String(),
      'delivery_status': status.storageValue,
      'platform_id': platformId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static NotificationDelivery fromMap(Map<String, Object?> map) {
    return NotificationDelivery(
      id: map['id'] as String?,
      scheduleId: map['schedule_id'] as String,
      deliveredAt: DateTime.parse(map['delivered_at'] as String),
      status: NotificationDeliveryStatusX.fromStorage(
        map['delivery_status'] as String?,
      ),
      platformId: map['platform_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class NotificationDeliveryView {
  const NotificationDeliveryView({
    required this.delivery,
    required this.scheduleType,
  });

  final NotificationDelivery delivery;
  final NotificationScheduleType? scheduleType;

  static NotificationDeliveryView fromMap(Map<String, Object?> map) {
    final delivery = NotificationDelivery.fromMap(map);
    final raw = map['schedule_type'] as String?;
    return NotificationDeliveryView(
      delivery: delivery,
      scheduleType: _parseScheduleType(raw),
    );
  }

  static NotificationScheduleType? _parseScheduleType(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final value in NotificationScheduleType.values) {
      if (value.name == raw) return value;
    }
    return null;
  }
}

class VerificationAttempt {
  VerificationAttempt({
    String? id,
    required this.windowId,
    required this.method,
    required this.startedAt,
    required this.result,
    this.completedAt,
    this.failureReason,
    Map<String, dynamic>? metadata,
  }) : id = id ?? _uuid.v4(),
       metadata = metadata == null ? null : Map<String, dynamic>.from(metadata);

  final String id;
  final String windowId;
  final VerificationMethod method;
  final DateTime startedAt;
  final DateTime? completedAt;
  final VerificationResult result;
  final VerificationFailureReason? failureReason;
  final Map<String, dynamic>? metadata;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'window_id': windowId,
      'method': method.storageValue,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'result': result.storageValue,
      'failure_reason': failureReason?.storageValue,
      'metadata': metadata == null ? null : jsonEncode(metadata),
    };
  }

  static VerificationAttempt fromMap(Map<String, Object?> map) {
    final metadataRaw = map['metadata'] as String?;
    return VerificationAttempt(
      id: map['id'] as String?,
      windowId: map['window_id'] as String,
      method: VerificationMethodX.fromStorage(map['method'] as String?),
      startedAt: DateTime.parse(map['started_at'] as String),
      completedAt: map['completed_at'] == null
          ? null
          : DateTime.parse(map['completed_at'] as String),
      result: VerificationResultX.fromStorage(map['result'] as String?),
      failureReason: VerificationFailureReasonX.fromStorage(
        map['failure_reason'] as String?,
      ),
      metadata: metadataRaw == null
          ? null
          : jsonDecode(metadataRaw) as Map<String, dynamic>,
    );
  }
}

class AlarmState {
  AlarmState({
    String? id,
    required this.windowId,
    required this.status,
    required this.snoozeCount,
    required this.lastChangedAt,
  }) : id = id ?? _uuid.v4();

  final String id;
  final String windowId;
  final AlarmStatus status;
  final int snoozeCount;
  final DateTime lastChangedAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'window_id': windowId,
      'status': status.storageValue,
      'snooze_count': snoozeCount,
      'last_changed_at': lastChangedAt.toIso8601String(),
    };
  }

  static AlarmState fromMap(Map<String, Object?> map) {
    return AlarmState(
      id: map['id'] as String?,
      windowId: map['window_id'] as String,
      status: AlarmStatusX.fromStorage(map['status'] as String?),
      snoozeCount: map['snooze_count'] as int? ?? 0,
      lastChangedAt: DateTime.parse(map['last_changed_at'] as String),
    );
  }
}

class NotificationPlan {
  const NotificationPlan({required this.window, required this.schedules});

  final BedtimeWindow window;
  final List<NotificationSchedule> schedules;
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

DateTime _dateFromKey(String? key) {
  if (key == null || key.isEmpty) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
  return DateTime.parse(key);
}

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}
