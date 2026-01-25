import 'app_mode.dart';
import 'verification_method.dart';

class UserSettings {
  const UserSettings({
    required this.isOnboarded,
    required this.name,
    required this.bedtimeStart,
    required this.bedtimeEnd,
    required this.mode,
    required this.verificationMethod,
    required this.streak,
    required this.lastBrushDate,
    required this.lastBrushTime,
  });

  final bool isOnboarded;
  final String name;
  final String bedtimeStart;
  final String bedtimeEnd;
  final AppMode mode;
  final VerificationMethod verificationMethod;
  final int streak;
  final String? lastBrushDate;
  final String? lastBrushTime;

  UserSettings copyWith({
    bool? isOnboarded,
    String? name,
    String? bedtimeStart,
    String? bedtimeEnd,
    AppMode? mode,
    VerificationMethod? verificationMethod,
    int? streak,
    String? lastBrushDate,
    String? lastBrushTime,
  }) {
    return UserSettings(
      isOnboarded: isOnboarded ?? this.isOnboarded,
      name: name ?? this.name,
      bedtimeStart: bedtimeStart ?? this.bedtimeStart,
      bedtimeEnd: bedtimeEnd ?? this.bedtimeEnd,
      mode: mode ?? this.mode,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      streak: streak ?? this.streak,
      lastBrushDate: lastBrushDate ?? this.lastBrushDate,
      lastBrushTime: lastBrushTime ?? this.lastBrushTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isOnboarded': isOnboarded,
      'name': name,
      'bedtimeStart': bedtimeStart,
      'bedtimeEnd': bedtimeEnd,
      'mode': mode.storageValue,
      'verificationMethod': verificationMethod.storageValue,
      'streak': streak,
      'lastBrushDate': lastBrushDate,
      'lastBrushTime': lastBrushTime,
    };
  }

  static UserSettings fromJson(Map<String, dynamic> json) {
    return UserSettings(
      isOnboarded: json['isOnboarded'] as bool? ?? false,
      name: json['name'] as String? ?? '',
      bedtimeStart: json['bedtimeStart'] as String? ?? '22:00',
      bedtimeEnd: json['bedtimeEnd'] as String? ?? '01:00',
      mode: AppModeX.fromStorage(json['mode'] as String?),
      verificationMethod: VerificationMethodX.fromStorage(
        json['verificationMethod'] as String?,
      ),
      streak: json['streak'] as int? ?? 0,
      lastBrushDate: json['lastBrushDate'] as String?,
      lastBrushTime: json['lastBrushTime'] as String?,
    );
  }

  static UserSettings defaults() {
    return const UserSettings(
      isOnboarded: false,
      name: '',
      bedtimeStart: '22:00',
      bedtimeEnd: '01:00',
      mode: AppMode.accountability,
      verificationMethod: VerificationMethod.manual,
      streak: 0,
      lastBrushDate: null,
      lastBrushTime: null,
    );
  }
}
