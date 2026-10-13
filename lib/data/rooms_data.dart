// ═══════════════ أنواع الألغاز ═══════════════
enum PuzzleType {
  mirrors,      // مرايا
  hiddenMessage,// رسالة مخفية
  lock,         // خزانة
  code,         // كود
  shadow,       // ظل (سحب)
  sound,        // أصوات
  photos,       // صور
  blood,        // دم
  rope,         // حبل (سحب)
}

// ═══════════════ عنصر في الغرفة ═══════════════
class RoomItem {
  final String id;
  final String name;
  final double x;      // نسبة من عرض الشاشة (0-1)
  final double y;      // نسبة من ارتفاع الشاشة (0-1)
  final double width;
  final double height;
  final String icon;   // اسم أيقونة (Material Icons)
  final bool isPuzzle;
  final String? puzzleId;

  const RoomItem({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.icon,
    this.isPuzzle = false,
    this.puzzleId,
  });
}

// ═══════════════ غرفة ═══════════════
class Room {
  final int id;
  final String title;
  final String description;
  final PuzzleType puzzleType;
  final List<RoomItem> items;
  final String nextRoomHint;

  const Room({
    required this.id,
    required this.title,
    required this.description,
    required this.puzzleType,
    required this.items,
    required this.nextRoomHint,
  });
}

// ═══════════════ 5 غرف ═══════════════
const List<Room> kRooms = [
  // ═══ الغرفة 1: البيت المهجور — المرايا ═══
  Room(
    id: 1,
    title: 'البيت المهجور',
    description:
        'بيت قديم. الأبواب بتصر. في 4 مرايا على الحيطة. '
        'كل مراية بتعكس حاجة مختلفة.',
    puzzleType: PuzzleType.mirrors,
    items: [
      RoomItem(
        id: 'mirror_1',
        name: 'مراية 1',
        x: 0.15,
        y: 0.35,
        width: 0.10,
        height: 0.25,
        icon: 'crop_portrait',
        isPuzzle: true,
        puzzleId: 'mirrors',
      ),
      RoomItem(
        id: 'mirror_2',
        name: 'مراية 2',
        x: 0.35,
        y: 0.35,
        width: 0.10,
        height: 0.25,
        icon: 'crop_portrait',
        isPuzzle: true,
        puzzleId: 'mirrors',
      ),
      RoomItem(
        id: 'mirror_3',
        name: 'مراية 3',
        x: 0.55,
        y: 0.35,
        width: 0.10,
        height: 0.25,
        icon: 'crop_portrait',
        isPuzzle: true,
        puzzleId: 'mirrors',
      ),
      RoomItem(
        id: 'mirror_4',
        name: 'مراية 4',
        x: 0.75,
        y: 0.35,
        width: 0.10,
        height: 0.25,
        icon: 'crop_portrait',
        isPuzzle: true,
        puzzleId: 'mirrors',
      ),
      RoomItem(
        id: 'note',
        name: 'ورقة على الأرض',
        x: 0.5,
        y: 0.8,
        width: 0.08,
        height: 0.08,
        icon: 'description',
      ),
      RoomItem(
        id: 'door',
        name: 'الباب',
        x: 0.9,
        y: 0.3,
        width: 0.08,
        height: 0.35,
        icon: 'door_front_door',
      ),
    ],
    nextRoomHint: 'الباب هيتفتح لما تحل اللغز.',
  ),

  // ═══ الغرفة 2: المدرسة المهجورة — الظل ═══
  Room(
    id: 2,
    title: 'المدرسة المهجورة',
    description:
        'فصل دراسي مهجور. كراسي مكسورة. في إضاءة غريبة بتتحرك. '
        'الظل على الحيطة شكله غريب.',
    puzzleType: PuzzleType.shadow,
    items: [
      RoomItem(
        id: 'light',
        name: 'الإضاءة',
        x: 0.5,
        y: 0.1,
        width: 0.10,
        height: 0.10,
        icon: 'lightbulb',
        isPuzzle: true,
        puzzleId: 'shadow',
      ),
      RoomItem(
        id: 'wall',
        name: 'الحيطة',
        x: 0.5,
        y: 0.5,
        width: 0.25,
        height: 0.30,
        icon: 'crop_landscape',
      ),
      RoomItem(
        id: 'chair',
        name: 'كرسي',
        x: 0.2,
        y: 0.75,
        width: 0.07,
        height: 0.10,
        icon: 'chair',
      ),
      RoomItem(
        id: 'board',
        name: 'سبورة',
        x: 0.8,
        y: 0.35,
        width: 0.13,
        height: 0.20,
        icon: 'tv',
      ),
      RoomItem(
        id: 'door',
        name: 'باب الفصل',
        x: 0.05,
        y: 0.3,
        width: 0.07,
        height: 0.35,
        icon: 'door_front_door',
      ),
    ],
    nextRoomHint: 'الإضاءة لازم تلف صح.',
  ),

  // ═══ الغرفة 3: المقبرة — الدم ═══
  Room(
    id: 3,
    title: 'المقبرة',
    description:
        'مقبرة قديمة. قبور مفتوحة. في خط دم على الأرض بيمشي في اتجاه. '
        'الدم لسه طري... يعني حد قريب.',
    puzzleType: PuzzleType.blood,
    items: [
      RoomItem(
        id: 'blood_1',
        name: 'قطرة دم',
        x: 0.2,
        y: 0.7,
        width: 0.05,
        height: 0.05,
        icon: 'water_drop',
      ),
      RoomItem(
        id: 'blood_2',
        name: 'قطرة دم',
        x: 0.35,
        y: 0.65,
        width: 0.05,
        height: 0.05,
        icon: 'water_drop',
      ),
      RoomItem(
        id: 'blood_3',
        name: 'قطرة دم',
        x: 0.5,
        y: 0.7,
        width: 0.05,
        height: 0.05,
        icon: 'water_drop',
      ),
      RoomItem(
        id: 'blood_4',
        name: 'قطرة دم',
        x: 0.65,
        y: 0.6,
        width: 0.05,
        height: 0.05,
        icon: 'water_drop',
      ),
      RoomItem(
        id: 'grave',
        name: 'قبر مفتوح',
        x: 0.8,
        y: 0.5,
        width: 0.12,
        height: 0.20,
        icon: 'dangerous',
        isPuzzle: true,
        puzzleId: 'blood',
      ),
      RoomItem(
        id: 'door',
        name: 'باب المقبرة',
        x: 0.05,
        y: 0.4,
        width: 0.06,
        height: 0.30,
        icon: 'door_front_door',
      ),
    ],
    nextRoomHint: 'اتبع الدم... بس خد بالك.',
  ),

  // ═══ الغرفة 4: المستشفى — الموسيقى ═══
  Room(
    id: 4,
    title: 'المستشفى المهجور',
    description:
        'مستشفى قديم. سراير فاضية. في صندوق موسيقى على مكتب. '
        'بيشغل نغمة غريبة... لازم تكررها.',
    puzzleType: PuzzleType.sound,
    items: [
      RoomItem(
        id: 'music_box',
        name: 'صندوق موسيقى',
        x: 0.5,
        y: 0.5,
        width: 0.10,
        height: 0.10,
        icon: 'music_note',
        isPuzzle: true,
        puzzleId: 'sound',
      ),
      RoomItem(
        id: 'bed_1',
        name: 'سرير',
        x: 0.2,
        y: 0.7,
        width: 0.10,
        height: 0.15,
        icon: 'hotel',
      ),
      RoomItem(
        id: 'bed_2',
        name: 'سرير',
        x: 0.8,
        y: 0.7,
        width: 0.10,
        height: 0.15,
        icon: 'hotel',
      ),
      RoomItem(
        id: 'cabinet',
        name: 'خزانة أدوية',
        x: 0.85,
        y: 0.3,
        width: 0.08,
        height: 0.15,
        icon: 'inventory_2',
      ),
      RoomItem(
        id: 'door',
        name: 'باب المستشفى',
        x: 0.05,
        y: 0.35,
        width: 0.06,
        height: 0.30,
        icon: 'door_front_door',
      ),
    ],
    nextRoomHint: 'النغمة... كررها صح.',
  ),

  // ═══ الغرفة 5: المخبأ — النهاية ═══
  Room(
    id: 5,
    title: 'المخبأ',
    description:
        'قبو تحت الأرض. الظلمة خانقة. في باب كبير في النهاية. '
        'ووراه... الحقيقة.',
    puzzleType: PuzzleType.code,
    items: [
      RoomItem(
        id: 'big_door',
        name: 'الباب الكبير',
        x: 0.5,
        y: 0.4,
        width: 0.20,
        height: 0.50,
        icon: 'door_front_door',
        isPuzzle: true,
        puzzleId: 'code',
      ),
      RoomItem(
        id: 'candle_1',
        name: 'شمعة',
        x: 0.2,
        y: 0.6,
        width: 0.04,
        height: 0.10,
        icon: 'local_fire_department',
      ),
      RoomItem(
        id: 'candle_2',
        name: 'شمعة',
        x: 0.8,
        y: 0.6,
        width: 0.04,
        height: 0.10,
        icon: 'local_fire_department',
      ),
      RoomItem(
        id: 'paper',
        name: 'ورقة قديمة',
        x: 0.15,
        y: 0.3,
        width: 0.07,
        height: 0.08,
        icon: 'description',
      ),
    ],
    nextRoomHint: 'الباب الأخير... الحقيقة وراه.',
  ),
];