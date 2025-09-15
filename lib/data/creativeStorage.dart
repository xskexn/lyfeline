import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'atoms.dart';
import 'dart:math';

class SharedCreativeStorage {
  final String aspectId;

  SharedCreativeStorage._(this.aspectId);

  static Future<SharedCreativeStorage> init(String aspectId) async {

    return SharedCreativeStorage._(aspectId);
  }

  String get atomsKey => "${aspectId}_atoms";
  String get pointsKey => "${aspectId}_points";
  String get lastResetKey => "${aspectId}_last_reset";
  String get levelKey => "${aspectId}_level";
  String get totalXpKey => "${aspectId}_totalXp";

  Future<void> saveData(List<Atom> atoms, int points) async {
    final prefs = await SharedPreferences.getInstance();
    final atomList = atoms.map((t) => t.toJson()).toList();
    await prefs.setString(atomsKey, jsonEncode(atomList));
    await prefs.setInt(pointsKey, points);
    await prefs.setString(lastResetKey, DateTime.now().toIso8601String());
    
    final int level = calculateLevel(points);
    await prefs.setInt(levelKey, level);
    
    await prefs.setInt(totalXpKey, points);
  }

  Future<(List<Atom>, int, DateTime?, int, int)> loadData(List<Atom> defaultAtoms) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString(atomsKey);
    final points = prefs.getInt(pointsKey) ?? 0;
    final lastResetStr = prefs.getString(lastResetKey);
    final level = prefs.getInt(levelKey) ?? 1;
    final totalXp = prefs.getInt(totalXpKey) ?? 0;

    List<Atom> tasks = defaultAtoms;
    if (tasksJson != null) {
      final decoded = jsonDecode(tasksJson) as List<dynamic>;
      tasks = decoded.map((t) => Atom.fromJson(t)).toList();
    }

    DateTime? lastReset = lastResetStr != null ? DateTime.parse(lastResetStr) : null;
    return (tasks, points, lastReset, level, totalXp);
  }

  int calculateLevel(int points) {
    if (points <= 0) return 1;
    
    return (sqrt(points / 25)).floor() + 1;
  }

  double getLevelProgress(int points, int currentLevel) {
    if (currentLevel <= 1) {
      return points / 25.0; 
    }
    
    final currentLevelThreshold = 25 * pow(currentLevel - 1, 2);
    final nextLevelThreshold = 25 * pow(currentLevel, 2);
    
    if (nextLevelThreshold == currentLevelThreshold) return 1.0;
    
    return (points - currentLevelThreshold) / (nextLevelThreshold - currentLevelThreshold);
  }

  double getXpForNextLevel(int points, int currentLevel) {
    final nextLevelThreshold = 25 * pow(currentLevel, 2);
    return (nextLevelThreshold - points).toDouble();
  }
}