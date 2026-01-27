enum AlarmTone { classic, pulse, chime }

extension AlarmToneX on AlarmTone {
  String get label {
    switch (this) {
      case AlarmTone.classic:
        return 'Classic';
      case AlarmTone.pulse:
        return 'Pulse';
      case AlarmTone.chime:
        return 'Chime';
    }
  }

  String get storageValue => name;

  String get androidResource {
    switch (this) {
      case AlarmTone.classic:
        return 'alarm_classic';
      case AlarmTone.pulse:
        return 'alarm_pulse';
      case AlarmTone.chime:
        return 'alarm_chime';
    }
  }

  String get iosFilename {
    switch (this) {
      case AlarmTone.classic:
        return 'alarm_classic.wav';
      case AlarmTone.pulse:
        return 'alarm_pulse.wav';
      case AlarmTone.chime:
        return 'alarm_chime.wav';
    }
  }

  String get assetPath {
    switch (this) {
      case AlarmTone.classic:
        return 'assets/sounds/alarm_classic.wav';
      case AlarmTone.pulse:
        return 'assets/sounds/alarm_pulse.wav';
      case AlarmTone.chime:
        return 'assets/sounds/alarm_chime.wav';
    }
  }

  static AlarmTone fromStorage(String? value) {
    return AlarmTone.values.firstWhere(
      (tone) => tone.name == value,
      orElse: () => AlarmTone.classic,
    );
  }
}
