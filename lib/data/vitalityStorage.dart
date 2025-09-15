import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'atoms.dart';

class SharedVitalityStorage {
  final String aspectId;

  SharedVitalityStorage._(this.aspectId);

  static Future<SharedVitalityStorage> init(String aspectId) async {
    return SharedVitalityStorage._(aspectId);
  }

  String get atomsKey => "${aspectId}_tasks";
  String get pointsKey => "${aspectId}_points";
  String get recordsKey => "${aspectId}_recordKey";
  String get lastResetKey => "${aspectId}_last_reset";
  String get levelKey => "${aspectId}_level";
  String get totalDaysKey => "${aspectId}_total_days";
  String get totalPointsKey => "${aspectId}_total_points";

  Future<void> saveData(List<Atom> atoms, int points, List<Map<String, dynamic>> vitalityRecords) async {
    final prefs = await SharedPreferences.getInstance();
    
    final atomsJson = jsonEncode(atoms.map((atom) => atom.toJson()).toList());
    await prefs.setString(atomsKey, atomsJson);
    
    await prefs.setInt(pointsKey, points);
    
    await prefs.setString(recordsKey, jsonEncode(vitalityRecords));
    
    await prefs.setString(lastResetKey, DateTime.now().toIso8601String());
  }

  int calculateLevel(int totalDays) {
    if (totalDays <= 0) return 1;
    return (totalDays / 7).ceil().clamp(1, 100);
  }

  double calculateLevelProgress(int totalDays, int currentLevel) {
    if (currentLevel <= 1) return totalDays / 7.0;
    
    final daysForCurrentLevel = (currentLevel - 1) * 7;
    final daysForNextLevel = currentLevel * 7;
    
    return ((totalDays - daysForCurrentLevel) / 7).clamp(0.0, 1.0);
  }

  Future<void> finaliseDay(int dailyPoints, List<Map<String, dynamic>> vitalityRecords) async {
    final prefs = await SharedPreferences.getInstance();
    
    final totalDays = prefs.getInt(totalDaysKey) ?? 0;
    final totalPoints = prefs.getInt(totalPointsKey) ?? 0;
    
    await prefs.setInt(totalDaysKey, totalDays + 1);
    await prefs.setInt(totalPointsKey, totalPoints + dailyPoints);
    
    final newTotalDays = totalDays + 1;
    final newLevel = calculateLevel(newTotalDays);
    await prefs.setInt(levelKey, newLevel);
    
    await prefs.setString(recordsKey, jsonEncode(vitalityRecords));
  }

  Future<(List<Atom>, int, DateTime?, List<Map<String, dynamic>>, int, double, int, int)> loadData(List<Atom> defaultAtoms) async {
    final prefs = await SharedPreferences.getInstance();
    
    final atomsJson = prefs.getString(atomsKey);
    List<Atom> atoms = defaultAtoms;
    if (atomsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(atomsJson);
        atoms = decoded.map((json) => Atom.fromJson(json)).toList();
      } catch (e) {
        print("Error loading atoms: $e");
      }
    }
    
    final points = prefs.getInt(pointsKey) ?? 0;
    
    final recordsJson = prefs.getString(recordsKey);
    List<Map<String, dynamic>> vitalityRecords = [];
    if (recordsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(recordsJson);
        vitalityRecords = decoded.cast<Map<String, dynamic>>();
      } catch (e) {
        print("Error loading vitality records: $e");
      }
    }
    
    final lastResetStr = prefs.getString(lastResetKey);
    DateTime? lastReset = lastResetStr != null ? DateTime.parse(lastResetStr) : null;
    
    final totalDays = prefs.getInt(totalDaysKey) ?? 0;
    final totalPoints = prefs.getInt(totalPointsKey) ?? 0;
    final level = prefs.getInt(levelKey) ?? 1;
    final progress = calculateLevelProgress(totalDays, level);
    
    return (atoms, points, lastReset, vitalityRecords, level, progress, totalDays, totalPoints);
  }

  Future<Map<String, dynamic>> getLevelData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final totalDays = prefs.getInt(totalDaysKey) ?? 0;
    final totalPoints = prefs.getInt(totalPointsKey) ?? 0;
    final level = prefs.getInt(levelKey) ?? 1;
    final progress = calculateLevelProgress(totalDays, level);
    
    return {
      'level': level,
      'progress': progress,
      'totalDays': totalDays,
      'totalPoints': totalPoints
    };
  }
}