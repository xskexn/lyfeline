import 'dart:convert';
import 'atoms.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class SharedGrowthStorage {
  final String aspectId;

  SharedGrowthStorage._(this.aspectId);

  static Future<SharedGrowthStorage> init(String aspectId) async {
    return SharedGrowthStorage._(aspectId);
  }

  String get growthValuesKey => "${aspectId}_growthValues";
  String get lastResetKey => "${aspectId}_last_reset";
  String get tagCountsKey => "${aspectId}_tagCounts";
  String get levelKey => "${aspectId}_level";
  String get totalXpKey => "${aspectId}_totalXp";
  String get completedProjectsKey => "${aspectId}_completedProjects";

  Future<void> saveData(List<Atom> atoms) async {
    final prefs = await SharedPreferences.getInstance();
    final atomsJson = jsonEncode(atoms.map((atom) => atom.toJson()).toList());
    await prefs.setString(growthValuesKey, atomsJson);
    await prefs.setString(lastResetKey, DateTime.now().toIso8601String());
  }

  Future<(List<Atom>, DateTime?)> loadData(List<Atom> defaultTasks) async {
    final prefs = await SharedPreferences.getInstance();
    final valuesJson = prefs.getString(growthValuesKey);
    final lastResetStr = prefs.getString(lastResetKey);

    List<Atom> atoms = defaultTasks;
    if (valuesJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(valuesJson);
        atoms = decoded.map((json) => Atom.fromJson(json)).toList();
      } catch (e) {
        print("Error loading task data: $e");
        atoms = defaultTasks;
      }
    }

    DateTime? lastReset = lastResetStr != null ? DateTime.parse(lastResetStr) : null;
    return (atoms, lastReset);
  }

  Future<void> updateTagCount(String tag, {int increment = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    final tagCountsJson = prefs.getString(tagCountsKey);
    
    Map<String, int> tagCounts = {};
    if (tagCountsJson != null) {
      try {
        final decoded = jsonDecode(tagCountsJson) as Map<String, dynamic>;
        tagCounts = decoded.map((key, value) => MapEntry(key, value as int));
      } catch (e) {
        print("Error loading tag counts: $e");
      }
    }
    
    tagCounts[tag] = (tagCounts[tag] ?? 0) + increment;
    
    await prefs.setString(tagCountsKey, jsonEncode(tagCounts));
    
    int completedProjects = prefs.getInt(completedProjectsKey) ?? 0;
    await prefs.setInt(completedProjectsKey, completedProjects + increment);
    
    int xpGained = 10 * increment; 
    
    await updateLevel(xpGained);
  }

  Future<void> updateLevel(int xpGained) async {
    final prefs = await SharedPreferences.getInstance();
    int currentLevel = prefs.getInt(levelKey) ?? 1;
    int totalXp = prefs.getInt(totalXpKey) ?? 0;
    
    totalXp += xpGained;
    await prefs.setInt(totalXpKey, totalXp);
    
    int newLevel = (sqrt(totalXp / 100)).floor() + 1;
    
    if (newLevel > currentLevel) {
      await prefs.setInt(levelKey, newLevel);
    }
  }

  Future<int> getCurrentLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(levelKey) ?? 1;
  }

  Future<int> getTotalXp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(totalXpKey) ?? 0;
  }

  Future<int> getCompletedProjects() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(completedProjectsKey) ?? 0;
  }

  Future<Map<String, int>> getTagCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final tagCountsJson = prefs.getString(tagCountsKey);
    
    if (tagCountsJson != null) {
      try {
        final decoded = jsonDecode(tagCountsJson) as Map<String, dynamic>;
        return decoded.map((key, value) => MapEntry(key, value as int));
      } catch (e) {
        print("Error loading tag counts: $e");
      }
    }
    
    return {};
  }

  Future<double> getLevelProgress() async {
    final totalXp = await getTotalXp();
    final currentLevel = await getCurrentLevel();
    
    int xpForCurrentLevel = 100 * pow(currentLevel - 1, 2).toInt();
    
    int xpForNextLevel = 100 * pow(currentLevel, 2).toInt();
    
    if (xpForNextLevel == xpForCurrentLevel) return 1.0;
    
    return (totalXp - xpForCurrentLevel) / (xpForNextLevel - xpForCurrentLevel);
  }

  Future<double> getXpForNextLevel() async {
    final totalXp = await getTotalXp();
    final currentLevel = await getCurrentLevel();
    
    double xpForNextLevel = 100 * pow(currentLevel, 2).toDouble();
    
    return xpForNextLevel - totalXp;
  }

  Future<Map<String, double>> getTagProgress() async {
    final tagCounts = await getTagCounts();
    final Map<String, double> progress = {};
    
    tagCounts.forEach((tag, count) {
      progress[tag] = count / 10.0; 
    });
    
    return progress;
  }
}