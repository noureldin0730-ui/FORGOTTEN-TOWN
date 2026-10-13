import 'package:shared_preferences/shared_preferences.dart';

class SaveManager {
  // ═══ الغرفة الحالية ═══
  static Future<int> getSavedRoom() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt('saved_room') ?? 1;
  }

  static Future<void> setSavedRoom(int room) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('saved_room', room);
    await p.setBool('has_saved', true);
  }

  static Future<bool> hasSavedGame() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('has_saved') ?? false;
  }

  static Future<void> clearAll() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
  }

  // ═══ المفاتيح اللي مع اللاعب ═══
  static Future<List<String>> getKeys() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList('player_keys') ?? [];
  }

  static Future<void> addKey(String keyName) async {
    final p = await SharedPreferences.getInstance();
    final keys = p.getStringList('player_keys') ?? [];
    if (!keys.contains(keyName)) {
      keys.add(keyName);
      await p.setStringList('player_keys', keys);
    }
  }

  static Future<bool> hasKey(String keyName) async {
    final p = await SharedPreferences.getInstance();
    final keys = p.getStringList('player_keys') ?? [];
    return keys.contains(keyName);
  }

  static Future<void> clearKeys() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('player_keys');
  }

  // ═══ الألغاز المحلولة ═══
  static Future<Set<String>> getSolved() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList('solved_puzzles') ?? []).toSet();
  }

  static Future<void> markSolved(String puzzleId) async {
    final p = await SharedPreferences.getInstance();
    final solved = (p.getStringList('solved_puzzles') ?? []).toSet();
    solved.add(puzzleId);
    await p.setStringList('solved_puzzles', solved.toList());
  }

  static Future<bool> isSolved(String puzzleId) async {
    final p = await SharedPreferences.getInstance();
    final solved = p.getStringList('solved_puzzles') ?? [];
    return solved.contains(puzzleId);
  }
}