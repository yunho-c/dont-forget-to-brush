import 'package:uuid/uuid.dart';

import 'notification_models.dart';

const _uuid = Uuid();

enum TagType { nfc, qr }

extension TagTypeX on TagType {
  String get label {
    switch (this) {
      case TagType.nfc:
        return 'NFC';
      case TagType.qr:
        return 'QR';
    }
  }

  String get storageValue => name;

  static TagType fromStorage(String? value) {
    return TagType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => TagType.nfc,
    );
  }
}

class SavedTag {
  SavedTag({
    String? id,
    required this.type,
    required this.name,
    required String credential,
    this.isActive = true,
    DateTime? createdAt,
    this.lastUsedAt,
  }) : id = id ?? _uuid.v4(),
       credential = normalizeTagCredential(credential),
       createdAt = createdAt ?? DateTime.now();

  final String id;
  final TagType type;
  final String name;
  final String credential;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  SavedTag copyWith({
    TagType? type,
    String? name,
    String? credential,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return SavedTag(
      id: id,
      type: type ?? this.type,
      name: name ?? this.name,
      credential: credential ?? this.credential,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  bool matchesCredential(String incoming) {
    return credential == normalizeTagCredential(incoming);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.storageValue,
      'name': name,
      'credential': credential,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
    };
  }

  static SavedTag fromJson(Map<String, dynamic> json) {
    return SavedTag(
      id: json['id'] as String?,
      type: TagTypeX.fromStorage(json['type'] as String?),
      name: json['name'] as String? ?? 'Tag',
      credential: json['credential'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: _dateOrNow(json['createdAt'] as String?),
      lastUsedAt: _dateOrNull(json['lastUsedAt'] as String?),
    );
  }

  static DateTime _dateOrNow(String? value) {
    final parsed = _dateOrNull(value);
    return parsed ?? DateTime.now();
  }

  static DateTime? _dateOrNull(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

enum NfcScanStatus {
  found,
  canceled,
  timedOut,
  unavailable,
  unsupported,
  error,
}

class NfcScanResult {
  const NfcScanResult({
    required this.status,
    this.identifier,
    this.message,
  });

  final NfcScanStatus status;
  final String? identifier;
  final String? message;

  bool get isFound => status == NfcScanStatus.found && identifier != null;

  static NfcScanResult found(String identifier) =>
      NfcScanResult(status: NfcScanStatus.found, identifier: identifier);

  static NfcScanResult canceled({String? message}) =>
      NfcScanResult(status: NfcScanStatus.canceled, message: message);

  static NfcScanResult timedOut({String? message}) =>
      NfcScanResult(status: NfcScanStatus.timedOut, message: message);

  static NfcScanResult unavailable({String? message}) =>
      NfcScanResult(status: NfcScanStatus.unavailable, message: message);

  static NfcScanResult unsupported({String? message}) =>
      NfcScanResult(status: NfcScanStatus.unsupported, message: message);

  static NfcScanResult error({String? message}) =>
      NfcScanResult(status: NfcScanStatus.error, message: message);
}

enum TagVerificationStatus {
  matched,
  noTagDetected,
  unrecognized,
  unavailable,
  error,
}

class TagVerificationResult {
  const TagVerificationResult({
    required this.status,
    required this.message,
    this.tag,
    this.failureReason,
    this.rawIdentifier,
  });

  final TagVerificationStatus status;
  final String message;
  final SavedTag? tag;
  final VerificationFailureReason? failureReason;
  final String? rawIdentifier;

  bool get isMatched => status == TagVerificationStatus.matched;

  static TagVerificationResult matched({
    required SavedTag tag,
    required String rawIdentifier,
  }) {
    return TagVerificationResult(
      status: TagVerificationStatus.matched,
      message: 'Tag matched: ${tag.name}',
      tag: tag,
      rawIdentifier: rawIdentifier,
    );
  }

  static TagVerificationResult noTagDetected({String? message}) {
    return TagVerificationResult(
      status: TagVerificationStatus.noTagDetected,
      message: message ?? 'No tag detected.',
      failureReason: VerificationFailureReason.noTag,
    );
  }

  static TagVerificationResult unrecognized({
    String? rawIdentifier,
    String? message,
  }) {
    return TagVerificationResult(
      status: TagVerificationStatus.unrecognized,
      message: message ?? 'This tag is not registered.',
      failureReason: VerificationFailureReason.wrongTag,
      rawIdentifier: rawIdentifier,
    );
  }

  static TagVerificationResult unavailable({String? message}) {
    return TagVerificationResult(
      status: TagVerificationStatus.unavailable,
      message: message ?? 'NFC is unavailable on this device.',
      failureReason: VerificationFailureReason.permissionDenied,
    );
  }

  static TagVerificationResult error({String? message}) {
    return TagVerificationResult(
      status: TagVerificationStatus.error,
      message: message ?? 'Tag verification failed. Try again.',
      failureReason: VerificationFailureReason.other,
    );
  }
}

String normalizeTagCredential(String value) {
  return value.trim().replaceAll(RegExp(r'\\s+'), '').toLowerCase();
}

String formatTagCredential(String value, {int tail = 8}) {
  final normalized = normalizeTagCredential(value);
  if (normalized.length <= tail) return normalized.toUpperCase();
  return normalized.substring(normalized.length - tail).toUpperCase();
}
