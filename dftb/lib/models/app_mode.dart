enum AppMode { gentle, accountability, noExcuses }

extension AppModeX on AppMode {
  String get label {
    switch (this) {
      case AppMode.gentle:
        return 'Gentle';
      case AppMode.accountability:
        return 'Accountability';
      case AppMode.noExcuses:
        return 'No Excuses';
    }
  }

  String get storageValue => name;

  static AppMode fromStorage(String? value) {
    return AppMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AppMode.accountability,
    );
  }
}
