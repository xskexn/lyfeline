import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedAcademicStorage {
  final String aspectId;

  SharedAcademicStorage._(this.aspectId);

  static Future<SharedAcademicStorage> init(String aspectId) async {
    return SharedAcademicStorage._(aspectId);
  }

  String get academicalValuesKey => "${aspectId}_academicalValues";
  String get lastResetKey => "${aspectId}_last_reset";
  String get moduleNamesKey => "${aspectId}_moduleNames";
  String get currentTermKey => "${aspectId}_currentTerm";
  String get overallLevelKey => "${aspectId}_overall_level";
  String get levelProgressKey => "${aspectId}_level_progress";

  Future<void> saveData(Map<String, dynamic> academicalData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(academicalValuesKey, jsonEncode(academicalData));
    await prefs.setString(lastResetKey, DateTime.now().toIso8601String());
    
    final levelData = calculateLevelAndProgress(academicalData);
    await prefs.setInt(overallLevelKey, levelData['level']);
    await prefs.setDouble(levelProgressKey, levelData['progress']);
  }

  Map<String, dynamic> calculateLevelAndProgress(Map<String, dynamic> academicalData) {
    double totalScore = 0;
    int itemCount = 0;
    
    final attendance = academicalData['attendance'] ?? {};
    attendance.forEach((term, values) {
      if (values is List && values.length == 3) {
        final termAverage = (values[0] + values[1] + values[2]) / 3;
        totalScore += termAverage;
        itemCount++;
      }
    });
    
    final grades = academicalData['grades'] ?? {};
    grades.forEach((module, gradeList) {
      if (gradeList is List) {
        double moduleTotal = 0;
        double totalWeight = 0;
        
        for (var gradeData in gradeList) {
          if (gradeData is Map && gradeData.containsKey('grade') && gradeData.containsKey('weight')) {
            moduleTotal += gradeData['grade'] * gradeData['weight'];
            totalWeight += gradeData['weight'];
          }
        }
        
        if (totalWeight > 0) {
          totalScore += (moduleTotal / totalWeight) * 100;
          itemCount++;
        }
      }
    });
    
    if (itemCount == 0) {
      return {'level': 1, 'progress': 0.0};
    }
    
    final averageScore = totalScore / itemCount;
    
    final level = (averageScore / 20).ceil().clamp(1, 100);
    
    final currentLevel = (level - 1) * 20;
    final progress = ((averageScore - currentLevel) / 20).clamp(0.0, 1.0);
    
    return {'level': level, 'progress': progress};
  }

  Future<void> saveModuleNames(List<String> moduleNames) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(moduleNamesKey, jsonEncode(moduleNames));
  }

  Future<List<String>> getModuleNames() async {
    final prefs = await SharedPreferences.getInstance();
    final namesJson = prefs.getString(moduleNamesKey);
    if (namesJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(namesJson);
        return decoded.cast<String>();
      } catch (e) {
        print("Error loading module names: $e");
      }
    }
    return ["Module 1", "Module 2", "Module 3"];
  }

  Future<void> startNewTerm() async {
    final prefs = await SharedPreferences.getInstance();
    final currentTerm = prefs.getInt(currentTermKey) ?? 1;
    await prefs.setInt(currentTermKey, currentTerm + 1);
    
    final academicalData = await loadAcademicalData();
    await saveData({
      'attendance': {"Term $currentTerm": [0, 0, 0]},
      'grades': {"Term $currentTerm": {}}
    });
  }

  Future<Map<String, dynamic>> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final valuesJson = prefs.getString(academicalValuesKey);
    final lastResetStr = prefs.getString(lastResetKey);

    Map<String, dynamic> academicalData = {
      'attendance': {"Winter Module": [0, 0, 0], "Spring Module": [0, 0, 0], "Summer Module": [0, 0, 0]},
      'grades': {}
    };

    if (valuesJson != null) {
      try {
        academicalData = Map<String, dynamic>.from(jsonDecode(valuesJson));
      } catch (e) {
        print("Error loading academical data: $e");
      }
    }

    return academicalData;
  }


  Future<Map<String, dynamic>> getLevelData() async {
    final prefs = await SharedPreferences.getInstance();
    final level = prefs.getInt(overallLevelKey) ?? 1;
    final progress = prefs.getDouble(levelProgressKey) ?? 0.0;
    
    return {'level': level, 'progress': progress};
  }

  Future<Map<String, dynamic>> loadAcademicalData() async {
    final prefs = await SharedPreferences.getInstance();
    final valuesJson = prefs.getString(academicalValuesKey);
    return valuesJson != null ? Map<String, dynamic>.from(jsonDecode(valuesJson)) : {};
  }
}