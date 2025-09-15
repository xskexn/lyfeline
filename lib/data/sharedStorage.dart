import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Levels {
  double academicLevel = 0.0;
  double academicProgress = 0.0;

  double vitalityLevel = 0.0;
  double vitalityProgress = 0.0;

  double financialLevel = 0.0;
  double financialProgress = 0.0;

  double careLevel = 0.0;
  double careProgress = 0.0;

  double fitnessLevel = 0.0;
  double fitnessProgress = 0.0;

  double growthLevel = 0.0;
  double growthProgress = 0.0;

  double creativeLevel = 0.0;
  double creativeProgress = 0.0;

  double get general {
    final values = [
      academicLevel,
      vitalityLevel,
      financialLevel,
      careLevel,
      fitnessLevel,
      growthLevel,
      creativeLevel,
    ];
    return values.reduce((a, b) => a + b) / values.length;
  }

  double get generalSelfProgress {
    final values = [
      academicProgress,
      vitalityProgress,
      financialProgress,
      careProgress,
      fitnessProgress,
      growthProgress,
      creativeProgress,
    ];
    return values.reduce((a, b) => a + b) / values.length;
  }

  Future<void> saveLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final levelsMap = {
      'academicLevel': academicLevel,
      'academicProgress': academicProgress,
      'vitalityLevel': vitalityLevel,
      'vitalityProgress': vitalityProgress,
      'financialLevel': financialLevel,
      'financialProgress': financialProgress,
      'careLevel': careLevel,
      'careProgress': careProgress,
      'fitnessLevel': fitnessLevel,
      'fitnessProgress': fitnessProgress,
      'growthLevel': growthLevel,
      'growthProgress': growthProgress,
      'creativeLevel': creativeLevel,
      'creativeProgress': creativeProgress,
    };
    await prefs.setString('userLevels', jsonEncode(levelsMap));
  }

  Future<void> loadLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final levelsJson = prefs.getString('userLevels');
    
    if (levelsJson != null) {
      try {
        final levelsMap = jsonDecode(levelsJson) as Map<String, dynamic>;
        
        academicLevel = (levelsMap['academicLevel'] as num?)?.toDouble() ?? 0.0;
        academicProgress = (levelsMap['academicProgress'] as num?)?.toDouble() ?? 0.0;
        
        vitalityLevel = (levelsMap['vitalityLevel'] as num?)?.toDouble() ?? 0.0;
        vitalityProgress = (levelsMap['vitalityProgress'] as num?)?.toDouble() ?? 0.0;
        
        financialLevel = (levelsMap['financialLevel'] as num?)?.toDouble() ?? 0.0;
        financialProgress = (levelsMap['financialProgress'] as num?)?.toDouble() ?? 0.0;
        
        careLevel = (levelsMap['careLevel'] as num?)?.toDouble() ?? 0.0;
        careProgress = (levelsMap['careProgress'] as num?)?.toDouble() ?? 0.0;
        
        fitnessLevel = (levelsMap['fitnessLevel'] as num?)?.toDouble() ?? 0.0;
        fitnessProgress = (levelsMap['fitnessProgress'] as num?)?.toDouble() ?? 0.0;
        
        growthLevel = (levelsMap['growthLevel'] as num?)?.toDouble() ?? 0.0;
        growthProgress = (levelsMap['growthProgress'] as num?)?.toDouble() ?? 0.0;
        
        creativeLevel = (levelsMap['creativeLevel'] as num?)?.toDouble() ?? 0.0;
        creativeProgress = (levelsMap['creativeProgress'] as num?)?.toDouble() ?? 0.0;
      } catch (e) {
        print("Error loading levels: $e");
      }
    }
  }

  void updateLevel(String aspect, double level, double progress) {
    switch (aspect) {
      case 'academic':
        academicLevel = level;
        academicProgress = progress;
        break;
      case 'vitality':
        vitalityLevel = level;
        vitalityProgress = progress;
        break;
      case 'financial':
        financialLevel = level;
        financialProgress = progress;
        break;
      case 'care':
        careLevel = level;
        careProgress = progress;
        break;
      case 'fitness':
        fitnessLevel = level;
        fitnessProgress = progress;
        break;
      case 'growth':
        growthLevel = level;
        growthProgress = progress;
        break;
      case 'creative':
        creativeLevel = level;
        creativeProgress = progress;
        break;
    }
    saveLevels();
  }
}

final Levels userLevels = Levels();