enum RoutinePhase { morning, night }

extension RoutinePhaseX on RoutinePhase {
  String get label {
    switch (this) {
      case RoutinePhase.morning:
        return 'Morning';
      case RoutinePhase.night:
        return 'Night';
    }
  }
}

class RoutineCopy {
  const RoutineCopy({
    required this.phase,
    required this.alarm,
    required this.verify,
    required this.success,
    required this.methods,
  });

  final RoutinePhase phase;
  final RoutineAlarmCopy alarm;
  final RoutineVerifyCopy verify;
  final RoutineSuccessCopy success;
  final RoutineMethodCopy methods;

  static const RoutineCopy morning = RoutineCopy(
    phase: RoutinePhase.morning,
    alarm: RoutineAlarmCopy(
      pill: 'Morning check-in',
      title: 'Wake up and brush',
      body: 'Start the day with beautiful teeth.',
      ctaTitle: "Let's do it",
      ctaSubtitle: 'Start check-in',
      skipLabel: 'Skip for now',
    ),
    verify: RoutineVerifyCopy(
      alarmBadge: 'Alarm Active',
      title: 'Brush check',
      subtitle: 'Kick off the morning strong.',
    ),
    success: RoutineSuccessCopy(
      title: 'Off to a great start!',
      subtitle: 'Have a great day.',
    ),
    methods: RoutineMethodCopy.shared,
  );

  static const RoutineCopy night = RoutineCopy(
    phase: RoutinePhase.night,
    alarm: RoutineAlarmCopy(
      pill: 'Bedtime check-in',
      title: 'Brush before bed',
      body: 'Close out the night with a real check-in.',
      ctaTitle: "Let's do it",
      ctaSubtitle: 'Start check-in',
      skipLabel: 'Skip for now',
    ),
    verify: RoutineVerifyCopy(
      alarmBadge: 'Alarm Active',
      title: 'Brush check',
      subtitle: 'Let\'s finish the day strong.',
    ),
    success: RoutineSuccessCopy(
      title: 'Good night!',
      subtitle: 'Sleep well.',
    ),
    methods: RoutineMethodCopy.shared,
  );

  static RoutineCopy forPhase(RoutinePhase phase) {
    switch (phase) {
      case RoutinePhase.morning:
        return RoutineCopy.morning;
      case RoutinePhase.night:
        return RoutineCopy.night;
    }
  }
}

class RoutineAlarmCopy {
  const RoutineAlarmCopy({
    required this.pill,
    required this.title,
    required this.body,
    required this.ctaTitle,
    required this.ctaSubtitle,
    required this.skipLabel,
  });

  final String pill;
  final String title;
  final String body;
  final String ctaTitle;
  final String ctaSubtitle;
  final String skipLabel;
}

class RoutineVerifyCopy {
  const RoutineVerifyCopy({
    required this.alarmBadge,
    required this.title,
    required this.subtitle,
  });

  final String alarmBadge;
  final String title;
  final String subtitle;
}

class RoutineSuccessCopy {
  const RoutineSuccessCopy({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

class RoutineMethodCopy {
  const RoutineMethodCopy({
    required this.manual,
    required this.nfc,
    required this.selfie,
    required this.manualVerify,
    required this.nfcVerify,
    required this.selfieVerify,
  });

  final MethodChipCopy manual;
  final MethodChipCopy nfc;
  final MethodChipCopy selfie;
  final ManualVerifyCopy manualVerify;
  final NfcVerifyCopy nfcVerify;
  final SelfieVerifyCopy selfieVerify;

  static const RoutineMethodCopy shared = RoutineMethodCopy(
    manual: MethodChipCopy(
      alarmLabel: 'Hold to verify',
      alarmHint: 'Keep pressure steady until it completes.',
    ),
    nfc: MethodChipCopy(
      alarmLabel: 'Tap your tag',
      alarmHint: 'Hold your device near the NFC tag.',
    ),
    selfie: MethodChipCopy(
      alarmLabel: 'Take a selfie',
      alarmHint: 'Frame your face inside the guide.',
    ),
    manualVerify: ManualVerifyCopy(verifyHoldLabel: 'Hold'),
    nfcVerify: NfcVerifyCopy(
      verifyScanningLabel: 'Scanning for tag...',
      verifySimulateLabel: '(Simulate Tap)',
    ),
    selfieVerify: SelfieVerifyCopy(
      verifyCameraLabel: 'Simulating Camera...',
      verifyCaptureLabel: 'Take Photo',
    ),
  );
}

class MethodChipCopy {
  const MethodChipCopy({required this.alarmLabel, required this.alarmHint});

  final String alarmLabel;
  final String alarmHint;
}

class ManualVerifyCopy {
  const ManualVerifyCopy({required this.verifyHoldLabel});

  final String verifyHoldLabel;
}

class NfcVerifyCopy {
  const NfcVerifyCopy({
    required this.verifyScanningLabel,
    required this.verifySimulateLabel,
  });

  final String verifyScanningLabel;
  final String verifySimulateLabel;
}

class SelfieVerifyCopy {
  const SelfieVerifyCopy({
    required this.verifyCameraLabel,
    required this.verifyCaptureLabel,
  });

  final String verifyCameraLabel;
  final String verifyCaptureLabel;
}
