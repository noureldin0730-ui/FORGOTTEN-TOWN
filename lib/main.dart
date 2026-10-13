import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/room_screen.dart';
import 'data/save_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const ForgottenTownApp());
}

class ForgottenTownApp extends StatelessWidget {
  const ForgottenTownApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'البلدة المنسية',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
          ),
          child: child!,
        );
      },
      home: const StartScreen(),
    );
  }
}

// ═══════════ الألوان ═══════════
class P {
  static const black = Color(0xFF000000);
  static const dark = Color(0xFF0A0808);
  static const dim = Color(0xFF1A1614);
  static const line = Color(0xFF2A2420);
  static const gray = Color(0xFF6A5A50);
  static const white = Color(0xFFD8D0C8);
  static const blood = Color(0xFF8B0000);
  static const rare = Color(0xFFC1272D);
  static const gold = Color(0xFFB8945C);
  static const ghost = Color(0xFF3A2A2A);
  static const hint = Color(0xFF6B4F3A);
}

// ═══════════ شاشة البداية ═══════════
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});
  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _flicker;
  int _savedRoom = 1;
  bool _hasSaved = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _flicker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat(reverse: true);
    _load();
  }

  Future<void> _load() async {
    final saved = await SaveManager.hasSavedGame();
    final room = await SaveManager.getSavedRoom();
    if (!mounted) return;
    setState(() {
      _hasSaved = saved;
      _savedRoom = room;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _flicker.dispose();
    super.dispose();
  }

  void _startNew() {
    HapticFeedback.heavyImpact();
    SaveManager.clearAll();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RoomScreen(roomId: 1)),
    );
  }

  void _continue() {
    HapticFeedback.heavyImpact();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => RoomScreen(roomId: _savedRoom)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: P.black,
        body: Center(child: CircularProgressIndicator(color: P.rare)),
      );
    }

    return Scaffold(
      backgroundColor: P.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              AnimatedBuilder(
                animation: _flicker,
                builder: (context, child) {
                  return Opacity(
                    opacity: 0.6 + (_flicker.value * 0.4),
                    child: Column(
                      children: [
                        const Text(
                          'البلدة المنسية',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            color: P.rare,
                            fontSize: 52,
                            letterSpacing: 8,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(color: P.blood, blurRadius: 40),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(width: 100, height: 1, color: P.blood),
                        const SizedBox(height: 8),
                        const Text(
                          'FORGOTTEN TOWN',
                          style: TextStyle(
                            color: P.gray,
                            fontSize: 12,
                            letterSpacing: 6,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              const Text(
                'إنت صحيت... بس مش لوحدك',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: P.gray,
                  fontSize: 14,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 30),
              if (_hasSaved) ...[
                GestureDetector(
                  onTap: _continue,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: P.rare.withOpacity(0.3),
                      border: Border.all(color: P.rare, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: P.blood.withOpacity(0.4),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      'كمّل من الغرفة $_savedRoom',
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        color: P.white,
                        fontSize: 16,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              GestureDetector(
                onTap: _startNew,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: P.blood, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: P.blood.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    _hasSaved ? 'ابدأ من الأول' : 'ادخل البلدة',
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      color: P.white,
                      fontSize: 18,
                      letterSpacing: 6,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Nour Eldin',
                  style: TextStyle(
                    color: P.gray,
                    fontSize: 11,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}