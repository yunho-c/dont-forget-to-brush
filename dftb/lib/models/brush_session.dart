import 'package:uuid/uuid.dart';

import 'verification_method.dart';

const _uuid = Uuid();

class BrushSession {
  BrushSession({
    String? id,
    required this.timestamp,
    required this.method,
    required this.wasLate,
    required this.durationSeconds,
  }) : id = id ?? _uuid.v4();

  final String id;
  final DateTime timestamp;
  final VerificationMethod method;
  final bool wasLate;
  final int durationSeconds;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'method': method.storageValue,
      'was_late': wasLate ? 1 : 0,
      'duration_seconds': durationSeconds,
    };
  }

  static BrushSession fromMap(Map<String, Object?> map) {
    return BrushSession(
      id: map['id'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      method: VerificationMethodX.fromStorage(map['method'] as String?),
      wasLate: (map['was_late'] as int? ?? 0) == 1,
      durationSeconds: map['duration_seconds'] as int? ?? 120,
    );
  }
}
