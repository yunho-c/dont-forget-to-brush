enum VerificationMethod { manual, nfc, selfie }

extension VerificationMethodX on VerificationMethod {
  String get label {
    switch (this) {
      case VerificationMethod.manual:
        return 'Manual';
      case VerificationMethod.nfc:
        return 'Tag';
      case VerificationMethod.selfie:
        return 'Selfie';
    }
  }

  String get storageValue => name;

  static VerificationMethod fromStorage(String? value) {
    return VerificationMethod.values.firstWhere(
      (method) => method.name == value,
      orElse: () => VerificationMethod.manual,
    );
  }
}
