import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/rooms_data.dart';
import '../data/save_manager.dart';
import 'game_over_screen.dart';

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

class RoomScreen extends StatefulWidget {
  final int roomId;
  const RoomScreen({super.key, required this.roomId});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  late Room _room;

  // حالة اللعب
  double _light = 1.0;
  int _wrongAttempts = 0;
  int _maxAttempts = 3;
  bool _showHint = false;
  String _hintText = '';
  bool _roomSolved = false;
  bool _showPuzzleOverlay = false;

  // الظل
  Timer? _lightTimer;
  Timer? _shadowTimer;
  Offset _shadowPos = Offset.zero;
  bool _shadowVisible = false;

  // حالة الألغاز
  List<int> _puzzleOrder = [];
  List<int> _playerOrder = [];
  String _codeInput = '';
  double _shadowRotation = 0.0;
  List<int> _soundSequence = [];
  List<int> _playerSoundSequence = [];
  bool _playingSound = false;

  @override
  void initState() {
    super.initState();
    _room = kRooms.firstWhere(
      (r) => r.id == widget.roomId,
      orElse: () => kRooms.last,
    );
    _initPuzzle();
    _startLightTimer();
    _startShadowTimer();
    SaveManager.setSavedRoom(widget.roomId);
  }

  @override
  void dispose() {
    _lightTimer?.cancel();
    _shadowTimer?.cancel();
    super.dispose();
  }

  void _initPuzzle() {
    final rng = Random(widget.roomId * 9973);
    switch (_room.puzzleType) {
      case PuzzleType.mirrors:
        _puzzleOrder = [2, 4, 1, 3];
        break;
      case PuzzleType.shadow:
        _shadowRotation = 0.0;
        break;
      case PuzzleType.blood:
        _puzzleOrder = [1, 2, 3, 4];
        break;
      case PuzzleType.sound:
        _soundSequence = List.generate(4, (_) => rng.nextInt(4));
        break;
      case PuzzleType.code:
        _puzzleOrder = [
          rng.nextInt(10),
          rng.nextInt(10),
          rng.nextInt(10),
          rng.nextInt(10),
        ];
        break;
      default:
        break;
    }
  }

  // ═══ الكشاف — بيضعف مع الوقت ═══
  void _startLightTimer() {
    _lightTimer = Timer.periodic(const Duration(milliseconds: 1000), (t) {
      if (!mounted || _roomSolved) return;
      setState(() => _light -= 0.01);
      if (_light <= 0) {
        t.cancel();
        _triggerGameOver('الكشاف خلص... الظلمة خدتك.');
      }
    });
  }

  // ═══ الظل — بيمر كل شوية ═══
  void _startShadowTimer() {
    _shadowTimer = Timer.periodic(const Duration(seconds: 5), (t) {
      if (!mounted || _roomSolved) return;
      final rng = Random();
      setState(() {
        _shadowPos = Offset(
          (rng.nextDouble() - 0.5) * 400,
          (rng.nextDouble() - 0.5) * 200,
        );
        _shadowVisible = true;
      });
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _shadowVisible = false);
      });
    });
  }

  void _wrongAttempt(String hint) {
    HapticFeedback.heavyImpact();
    setState(() {
      _wrongAttempts++;
      _light -= 0.15;
      _hintText = hint;
      _showHint = true;
    });
    if (_wrongAttempts >= _maxAttempts) {
      _triggerGameOver(_getFailReason());
    } else {
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) setState(() => _showHint = false);
      });
    }
  }

  String _getFailReason() {
    switch (_room.id) {
      case 1:
        return 'المرايا... ما لقيتش الترتيب الصح.';
      case 2:
        return 'الظل ما اتظبطش... الظلمة خدتك.';
      case 3:
        return 'الدم كان فخ... انت مش لوحدك.';
      case 4:
        return 'النغمة غلط... المستشفى صحي.';
      default:
        return 'الباب ما اتفتحش... خلاص.';
    }
  }

  void _onPuzzleSolved() {
    HapticFeedback.mediumImpact();
    SaveManager.markSolved('room_${_room.id}');
    setState(() {
      _roomSolved = true;
      _hintText = 'اللغز اتحل! الباب اتفتح.';
      _showHint = true;
      _showPuzzleOverlay = false;
    });
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      _goToNextRoom();
    });
  }

  void _goToNextRoom() {
    if (widget.roomId >= kRooms.length) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const EndScreen()),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RoomScreen(roomId: widget.roomId + 1),
      ),
    );
  }

  void _triggerGameOver(String reason) {
    _lightTimer?.cancel();
    _shadowTimer?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameOverScreen(
          reason: reason,
          roomId: widget.roomId,
          onRetry: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => RoomScreen(roomId: widget.roomId),
              ),
            );
          },
          onRestart: () {
            SaveManager.clearAll();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const RoomScreen(roomId: 1),
              ),
            );
          },
          onExit: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
    );
  }

  void _openPuzzle() {
    HapticFeedback.mediumImpact();
    setState(() => _showPuzzleOverlay = true);
  }

  void _closePuzzle() {
    setState(() => _showPuzzleOverlay = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: P.black,
      body: Stack(
        children: [
          // الظل
          if (_shadowVisible)
            Positioned(
              left: MediaQuery.of(context).size.width / 2 +
                  _shadowPos.dx -
                  40,
              top: MediaQuery.of(context).size.height / 2 +
                  _shadowPos.dy -
                  60,
              child: Container(
                width: 80,
                height: 120,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      P.gray.withOpacity(0.35),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
            ),

          // خلفية الغرفة
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [P.dim, P.dark, P.black],
              ),
            ),
          ),

          // محتوى الغرفة
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildRoomArea()),
                _buildBottomBar(),
              ],
            ),
          ),

          // الكشاف
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: _light.clamp(0.3, 1.0),
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    P.black.withOpacity(0.6),
                    P.black,
                  ],
                  stops: const [0.0, 0.4, 0.75, 1.0],
                ),
              ),
            ),
          ),

          // لغز مفتوح
          if (_showPuzzleOverlay) _buildPuzzleOverlay(),

          // التلميح
          if (_showHint)
            Positioned(
              top: 70,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: P.rare.withOpacity(0.15),
                    border: Border.all(color: P.rare, width: 2),
                  ),
                  child: Text(
                    _hintText,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      color: P.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══ الشريط العلوي ═══
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: P.gray),
              ),
              child: const Row(
                children: [
                  Icon(Icons.exit_to_app, color: P.gray, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'خروج',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(color: P.gray, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'الغرفة ${_room.id}/${kRooms.length}',
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              color: P.rare,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _room.title,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              color: P.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.lightbulb, color: P.gold, size: 14),
              const SizedBox(width: 6),
              Container(
                width: 80,
                height: 4,
                decoration: BoxDecoration(
                  color: P.line,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _light.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _light > 0.5
                          ? P.gold
                          : (_light > 0.2 ? P.rare : P.blood),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Row(
            children: List.generate(_maxAttempts, (i) {
              return Padding(
                padding: const EdgeInsets.only(left: 3),
                child: Icon(
                  i < (_maxAttempts - _wrongAttempts)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: i < (_maxAttempts - _wrongAttempts)
                      ? P.blood
                      : P.gray,
                  size: 12,
                ),
              );
            }),
          ),
          const SizedBox(width: 16),
          const Text(
            'Nour Eldin',
            style: TextStyle(
              color: P.gray,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ═══ منطقة الغرفة ═══
  Widget _buildRoomArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned(
              top: 10,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: P.dark.withOpacity(0.7),
                  border: Border.all(color: P.line),
                ),
                child: Text(
                  _room.description,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: P.white,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ),
            ),
            ..._room.items.map((item) => _buildItem(item, constraints)),
          ],
        );
      },
    );
  }

  Widget _buildItem(RoomItem item, BoxConstraints constraints) {
    return Positioned(
      left: constraints.maxWidth * item.x,
      top: constraints.maxHeight * item.y,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          if (item.isPuzzle && !_roomSolved) {
            _openPuzzle();
          } else if (item.id == 'door' && _roomSolved) {
            _goToNextRoom();
          } else if (item.id == 'door' && !_roomSolved) {
            setState(() {
              _hintText = 'الباب مقفول. لازم تحل اللغز الأول.';
              _showHint = true;
            });
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) setState(() => _showHint = false);
            });
          } else {
            setState(() {
              _hintText = '${item.name}... مفيش حاجة هنا.';
              _showHint = true;
            });
            Future.delayed(const Duration(milliseconds: 1200), () {
              if (mounted) setState(() => _showHint = false);
            });
          }
        },
        child: Container(
          width: constraints.maxWidth * item.width,
          height: constraints.maxHeight * item.height,
          decoration: BoxDecoration(
            color: P.dark,
            border: Border.all(
              color: item.isPuzzle ? P.rare : P.gray,
              width: item.isPuzzle ? 2 : 1,
            ),
            boxShadow: item.isPuzzle
                ? [
                    BoxShadow(
                      color: P.rare.withOpacity(0.3),
                      blurRadius: 12,
                    ),
                  ]
                : [],
          ),
          child: Icon(
            _getIcon(item.icon),
            color: item.isPuzzle ? P.rare : P.gray,
            size: 28,
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String name) {
    switch (name) {
      case 'crop_portrait':
        return Icons.crop_portrait;
      case 'description':
        return Icons.description;
      case 'door_front_door':
        return Icons.door_front_door;
      case 'lightbulb':
        return Icons.lightbulb;
      case 'crop_landscape':
        return Icons.crop_landscape;
      case 'chair':
        return Icons.chair;
      case 'tv':
        return Icons.tv;
      case 'water_drop':
        return Icons.water_drop;
      case 'dangerous':
        return Icons.dangerous;
      case 'music_note':
        return Icons.music_note;
      case 'hotel':
        return Icons.hotel;
      case 'inventory_2':
        return Icons.inventory_2;
      case 'local_fire_department':
        return Icons.local_fire_department;
      default:
        return Icons.help_outline;
    }
  }

  // ═══ الشريط السفلي ═══
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'اللغز: ${_getPuzzleName()}',
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              color: P.gold,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          if (_roomSolved)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: P.gold, width: 1.5),
              ),
              child: const Text(
                'الباب اتفتح — دوس على الباب',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: P.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getPuzzleName() {
    switch (_room.puzzleType) {
      case PuzzleType.mirrors:
        return 'المرايا';
      case PuzzleType.shadow:
        return 'الظل';
      case PuzzleType.blood:
        return 'الدم';
      case PuzzleType.sound:
        return 'النغمة';
      case PuzzleType.code:
        return 'الكود';
      default:
        return '—';
    }
  }

  // ═══ لغز مفتوح ═══
  Widget _buildPuzzleOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.92),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _closePuzzle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: P.gray),
                      ),
                      child: const Text(
                        'إلغاء',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(color: P.gray, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _getPuzzleName(),
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      color: P.rare,
                      fontSize: 18,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildPuzzleBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildPuzzleBody() {
    switch (_room.puzzleType) {
      case PuzzleType.mirrors:
        return _buildMirrorsPuzzle();
      case PuzzleType.shadow:
        return _buildShadowPuzzle();
      case PuzzleType.blood:
        return _buildBloodPuzzle();
      case PuzzleType.sound:
        return _buildSoundPuzzle();
      case PuzzleType.code:
        return _buildCodePuzzle();
      default:
        return const SizedBox();
    }
  }

  // ═══════════════════════════════════════
  // ═══════════ لغز المرايا ═══════════
  // ═══════════════════════════════════════
  Widget _buildMirrorsPuzzle() {
    const correctOrder = [2, 4, 1, 3];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '4 مرايا على الحيطة',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: P.gold,
              fontSize: 18,
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'دوس على المرايا بالترتيب الصح',
            textDirection: TextDirection.rtl,
            style: TextStyle(color: P.gray, fontSize: 12),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final mirrorNum = i + 1;
              final selected = _playerOrder.contains(mirrorNum);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    if (!_playerOrder.contains(mirrorNum)) {
                      _playerOrder.add(mirrorNum);
                    }
                    if (_playerOrder.length == 4) {
                      final isCorrect = _playerOrder.toString() ==
                          correctOrder.toString();
                      if (isCorrect) {
                        _onPuzzleSolved();
                      } else {
                        _playerOrder = [];
                        _wrongAttempt('الترتيب غلط... حاول تاني.');
                      }
                    }
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 80,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selected ? P.rare : P.gray,
                      width: selected ? 3 : 1.5,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: P.rare.withOpacity(0.5),
                              blurRadius: 20,
                            ),
                          ]
                        : [],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.crop_portrait,
                          color: selected ? P.rare : P.gray,
                          size: 40,
                        ),
                      ),
                      if (selected)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: P.rare,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$mirrorNum',
                              style: const TextStyle(
                                color: P.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          Text(
            'اخترت: ${_playerOrder.join(" → ")}',
            textDirection: TextDirection.rtl,
            style: const TextStyle(color: P.white, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: P.dark,
              border: Border.all(color: P.hint),
            ),
            child: const Text(
              '💡 الترتيب: 2 → 4 → 1 → 3',
              textDirection: TextDirection.rtl,
              style: TextStyle(color: P.hint, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // ═══════════ لغز الظل ═══════════
  // ═══════════════════════════════════════
  Widget _buildShadowPuzzle() {
    const targetAngle = 90.0;
    const tolerance = 10.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'لف الإضاءة',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: P.gold,
              fontSize: 18,
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'اسحب لفوق وتحت عشان تلف الإضاءة',
            textDirection: TextDirection.rtl,
            style: TextStyle(color: P.gray, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Container(
            width: 200,
            height: 150,
            decoration: BoxDecoration(
              color: P.dark,
              border: Border.all(color: P.gray),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: _shadowRotation * 3.14159 / 180,
                  child: Container(
                    width: 60,
                    height: 100,
                    decoration: BoxDecoration(
                      color: P.black.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  child: Container(
                    width: 60,
                    height: 4,
                    color: P.rare,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: P.gold),
            ),
            child: Text(
              '${_shadowRotation.toStringAsFixed(0)}° / 90°',
              style: const TextStyle(
                color: P.gold,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _shadowRotation =
                        (_shadowRotation - 5).clamp(0.0, 180.0);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: P.gray),
                  ),
                  child: const Icon(
                    Icons.arrow_left,
                    color: P.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () {
                  if ((_shadowRotation - targetAngle).abs() <= tolerance) {
                    _onPuzzleSolved();
                  } else {
                    _wrongAttempt('الظل مش مظبوط... جرب تاني.');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: P.rare,
                    border: Border.all(color: P.rare, width: 2),
                  ),
                  child: const Text(
                    'تأكيد',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: P.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _shadowRotation =
                        (_shadowRotation + 5).clamp(0.0, 180.0);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: P.gray),
                  ),
                  child: const Icon(
                    Icons.arrow_right,
                    color: P.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '💡 وصل لـ 90 درجة',
            textDirection: TextDirection.rtl,
            style: TextStyle(color: P.hint, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // ═══════════ لغز الدم ═══════════
  // ═══════════════════════════════════════
  Widget _buildBloodPuzzle() {
    const correctOrder = [1, 2, 3, 4];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'اتبع الدم',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: P.rare,
              fontSize: 18,
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'دوس على قطرات الدم بالترتيب',
            textDirection: TextDirection.rtl,
            style: TextStyle(color: P.gray, fontSize: 12),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final num = i + 1;
              final selected = _playerOrder.contains(num);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    if (!_playerOrder.contains(num)) {
                      _playerOrder.add(num);
                    }
                    if (_playerOrder.length == 4) {
                      final isCorrect = _playerOrder.toString() ==
                          correctOrder.toString();
                      if (isCorrect) {
                        _onPuzzleSolved();
                      } else {
                        _playerOrder = [];
                        _wrongAttempt('الترتيب غلط... الدم لسه طري.');
                      }
                    }
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? P.blood.withOpacity(0.6)
                        : Colors.transparent,
                    border: Border.all(
                      color: P.blood,
                      width: selected ? 3 : 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.water_drop,
                      color: selected ? P.white : P.blood,
                      size: 24,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          Text(
            'اخترت: ${_playerOrder.join(" → ")}',
            textDirection: TextDirection.rtl,
            style: const TextStyle(color: P.white, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: P.dark,
              border: Border.all(color: P.hint),
            ),
            child: const Text(
              '💡 الترتيب: 1 → 2 → 3 → 4',
              textDirection: TextDirection.rtl,
              style: TextStyle(color: P.hint, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // ═══════════ لغز النغمة ═══════════
  // ═══════════════════════════════════════
  Widget _buildSoundPuzzle() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'صندوق الموسيقى',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: P.gold,
              fontSize: 18,
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'كرر النغمة بنفس الترتيب',
            textDirection: TextDirection.rtl,
            style: TextStyle(color: P.gray, fontSize: 12),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _playingSound ? null : _playSoundSequence,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: P.gold),
              ),
              child: Text(
                _playingSound ? 'جاري التشغيل...' : '🎵 اسمع النغمة',
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  color: P.gold,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              return GestureDetector(
                onTap: _playingSound ? null : () => _onSoundButtonTap(i),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 70,
                  height: 70,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: P.dark,
                    border: Border.all(color: P.rare, width: 2),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: P.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          Text(
            'اخترت: ${_playerSoundSequence.map((e) => e + 1).join(" → ")}',
            textDirection: TextDirection.rtl,
            style: const TextStyle(color: P.white, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: P.dark,
              border: Border.all(color: P.hint),
            ),
            child: Text(
              '💡 النغمة: ${_soundSequence.map((e) => e + 1).join(" → ")}',
              textDirection: TextDirection.rtl,
              style: const TextStyle(color: P.hint, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _playSoundSequence() async {
    setState(() => _playingSound = true);
    for (int i = 0; i < _soundSequence.length; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      HapticFeedback.mediumImpact();
    }
    setState(() {
      _playingSound = false;
      _playerSoundSequence = [];
    });
  }

  void _onSoundButtonTap(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _playerSoundSequence.add(index);
      if (_playerSoundSequence.length == _soundSequence.length) {
        final isCorrect = _playerSoundSequence.toString() ==
            _soundSequence.toString();
        if (isCorrect) {
          _onPuzzleSolved();
        } else {
          _playerSoundSequence = [];
          _wrongAttempt('النغمة غلط... حاول تاني.');
        }
      }
    });
  }

  // ═══════════════════════════════════════
  // ═══════════ لغز الكود ═══════════
  // ═══════════════════════════════════════
  Widget _buildCodePuzzle() {
    final correctCode = _puzzleOrder.map((e) => e.toString()).join();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'الكود السري',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: P.gold,
              fontSize: 18,
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '4 أرقام',
            textDirection: TextDirection.rtl,
            style: TextStyle(color: P.gray, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 30,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: P.dark,
              border: Border.all(color: P.gold, width: 2),
            ),
            child: Text(
              _codeInput.isEmpty
                  ? '_ _ _ _'
                  : _codeInput.split('').join(' '),
              style: const TextStyle(
                color: P.white,
                fontSize: 32,
                letterSpacing: 6,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(10, (i) {
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    if (_codeInput.length < 4) {
                      _codeInput += i.toString();
                      if (_codeInput.length == 4) {
                        if (_codeInput == correctCode) {
                          _onPuzzleSolved();
                        } else {
                          _codeInput = '';
                          _wrongAttempt('الكود غلط... حاول تاني.');
                        }
                      }
                    }
                  });
                },
                child: Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: P.gray),
                  ),
                  child: Text(
                    '$i',
                    style: const TextStyle(
                      color: P.white,
                      fontSize: 20,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _codeInput = '');
            },
            child: const Text(
              'مسح',
              textDirection: TextDirection.rtl,
              style: TextStyle(color: P.gray, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: P.dark,
              border: Border.all(color: P.hint),
            ),
            child: Text(
              '💡 الكود: $correctCode',
              textDirection: TextDirection.rtl,
              style: const TextStyle(color: P.hint, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══ شاشة النهاية ═══
class EndScreen extends StatelessWidget {
  const EndScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: P.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'خرجت.',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: P.white,
                  fontSize: 48,
                  letterSpacing: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'بس... البلدة لسه منسية.',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: P.gray,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: P.rare, width: 2),
                  ),
                  child: const Text(
                    'من الأول',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: P.white,
                      fontSize: 16,
                      letterSpacing: 4,
                    ),
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