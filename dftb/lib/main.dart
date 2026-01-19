import 'package:shadcn_flutter/shadcn_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShadcnApp(
      title: "Don't Forget to Brush",
      home: MyHomePage(title: "Don't Forget to Brush"),
    );
  }
}

enum BrushView {
  dashboard,
  camera,
  nfc,
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const Color _pageBackground = Color(0xFFF1F5F9);
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _success = Color(0xFF16A34A);
  static const Color _successBackground = Color(0xFFDCFCE7);

  bool _hasBrushed = false;
  int _streak = 12;
  BrushView _view = BrushView.dashboard;
  bool _alarmActive = false;
  bool _isSnoozed = false;

  void _setView(BrushView view) {
    setState(() {
      _view = view;
    });
  }

  void _completeBrushing() {
    setState(() {
      _hasBrushed = true;
      _streak += 1;
      _view = BrushView.dashboard;
      _alarmActive = false;
      _isSnoozed = false;
    });
  }

  void _triggerAlarm() {
    setState(() {
      _alarmActive = true;
      _isSnoozed = false;
    });
  }

  void _snoozeAlarm() {
    setState(() {
      _alarmActive = false;
      _isSnoozed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> headers = _alarmActive
        ? const []
        : [
            AppBar(
              title: Text(widget.title),
              trailing: const [
                SecondaryBadge(child: Text('Tonight')),
              ],
            ),
            const Divider(),
          ];

    return Scaffold(
      backgroundColor: _pageBackground,
      headers: headers,
      child: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              top: headers.isEmpty,
              bottom: true,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: _buildView(),
                  ),
                ),
              ),
            ),
          ),
          if (_alarmActive) Positioned.fill(child: _buildAlarmOverlay()),
          if (_isSnoozed && !_alarmActive && !_hasBrushed)
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: SafeArea(
                top: false,
                child: _buildSnoozeToast(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildView() {
    switch (_view) {
      case BrushView.camera:
        return _buildCameraView();
      case BrushView.nfc:
        return _buildNfcView();
      case BrushView.dashboard:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    final Color statusColor =
        _hasBrushed ? _success : _muted;
    final Color statusBackground =
        _hasBrushed ? _successBackground : _pageBackground;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Gap(12),
          Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: statusBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _hasBrushed ? LucideIcons.circleCheck : LucideIcons.moon,
                  size: 48,
                  color: statusColor,
                ),
              ),
              const Gap(16),
              Text(
                _hasBrushed ? 'All clean!' : 'Good evening, Alex',
              ).semiBold(),
              const Gap(8),
              Text(
                _hasBrushed
                    ? 'Sweet dreams and pearly whites.'
                    : "You haven't brushed your teeth yet today.",
                textAlign: TextAlign.center,
              ).muted().small(),
            ],
          ),
          const Gap(24),
          Card(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE68A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.sun,
                    color: Color(0xFFB45309),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current Streak').semiBold(),
                      const Gap(2),
                      const Text('Keep it up!').muted().small(),
                    ],
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$_streak').semiBold(),
                    const Gap(4),
                    const Text('days').muted().small(),
                  ],
                ),
              ],
            ),
          ),
          if (!_hasBrushed) ...[
            const Gap(20),
            const Text('Verify Brushing').small().semiBold().muted(),
            const Gap(12),
            SizedBox(
              width: double.infinity,
              child: OutlineButton(
                onPressed: () => _setView(BrushView.camera),
                alignment: Alignment.centerLeft,
                leading: const Icon(LucideIcons.camera),
                child: const Text('Take a Selfie'),
              ),
            ),
            const Gap(12),
            SizedBox(
              width: double.infinity,
              child: OutlineButton(
                onPressed: () => _setView(BrushView.nfc),
                alignment: Alignment.centerLeft,
                leading: const Icon(LucideIcons.scan),
                child: const Text('Scan NFC Tag'),
              ),
            ),
            const Gap(8),
            GhostButton(
              onPressed: _completeBrushing,
              size: ButtonSize.small,
              child: const Text("I don't have my phone (Manual Confirm)"),
            ),
          ],
          const Gap(24),
          Card(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.clock, size: 16),
                    const Gap(8),
                    const Text('Routine Alarm').semiBold(),
                  ],
                ),
                Row(
                  children: [
                    const Text('11:00 PM').muted().small(),
                    const Gap(8),
                    const Icon(LucideIcons.chevronRight, size: 16),
                  ],
                ),
              ],
            ),
          ),
          const Gap(24),
          Center(
            child: GhostButton(
              onPressed: _triggerAlarm,
              size: ButtonSize.small,
              child: Text(
                'DEBUG: TRIGGER 11PM ALARM',
              ).muted().small(),
            ),
          ),
          const Gap(12),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: _ink,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton.ghost(
                    onPressed: () {},
                    size: ButtonSize.small,
                    icon: const Icon(
                      LucideIcons.settings,
                      color: _muted,
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 200,
                    height: 260,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0x33FFFFFF),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Align your toothbrush in frame',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color(0xCC020617),
                          Color(0x00020617),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton.ghost(
                          onPressed: () => _setView(BrushView.dashboard),
                          shape: ButtonShape.circle,
                          icon: const Icon(
                            LucideIcons.x,
                            color: Color(0xFFF8FAFC),
                          ),
                        ),
                        PrimaryButton(
                          onPressed: _completeBrushing,
                          size: ButtonSize.large,
                          shape: ButtonShape.circle,
                          child: const Icon(
                            LucideIcons.camera,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNfcView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2FE),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 160,
              height: 160,
              decoration: const BoxDecoration(
                color: Color(0xFFBAE6FD),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.smartphoneNfc,
                size: 48,
                color: Color(0xFF38BDF8),
              ),
            ),
          ],
        ),
        const Gap(24),
        const Text('Ready to Scan').semiBold(),
        const Gap(8),
        const Text(
          'Hold your phone near the NFC tag on your bathroom mirror.',
          textAlign: TextAlign.center,
        ).muted().small(),
        const Gap(24),
        GhostButton(
          onPressed: () => _setView(BrushView.dashboard),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildAlarmOverlay() {
    return Container(
      color: _ink,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Icon(
                  LucideIcons.clock,
                  color: const Color(0xFF64748B),
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.bell,
                      size: 48,
                      color: Color(0xFFF8FAFC),
                    ),
                  ),
                  const Gap(16),
                  const Text(
                    '11:00 PM',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF8FAFC),
                    ),
                  ),
                  const Gap(8),
                  const Text(
                    'Time to brush your teeth!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFCBD5F5),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      onPressed: _completeBrushing,
                      child: const Text("I'm Brushing Now"),
                    ),
                  ),
                  const Gap(12),
                  SizedBox(
                    width: double.infinity,
                    child: GhostButton(
                      onPressed: _snoozeAlarm,
                      child: const Text('Snooze for 10 min'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSnoozeToast() {
    return Card(
      filled: true,
      fillColor: _ink,
      borderColor: _ink,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: const Text(
        'Alarm snoozed until 11:10 PM',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFFF8FAFC),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
