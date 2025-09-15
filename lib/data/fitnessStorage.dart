import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class SharedFitnessStorage {
  final String aspectId;

  SharedFitnessStorage._(this.aspectId);

  static Future<SharedFitnessStorage> init(String aspectId) async {
    return SharedFitnessStorage._(aspectId);
  }

  String get muscleValuesKey => "${aspectId}_muscleValues";
  String get lastResetKey => "${aspectId}_last_reset";
  String get levelKey => "${aspectId}_level";
  String get totalProgressKey => "${aspectId}_totalProgress";
  String get userDataKey => "${aspectId}_userData";

  Future<void> saveData(Map<String, List<double>> muscleValues) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(muscleValuesKey, jsonEncode(muscleValues));
    await prefs.setString(lastResetKey, DateTime.now().toIso8601String());
    
    final double totalProgress = calculateTotalProgress(muscleValues);
    final int level = calculateLevel(totalProgress);
    
    await prefs.setDouble(totalProgressKey, totalProgress);
    await prefs.setInt(levelKey, level);
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userDataKey, jsonEncode(userData));
  }

  Future<Map<String, dynamic>> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataJson = prefs.getString(userDataKey);
    
    if (userDataJson != null) {
      try {
        return jsonDecode(userDataJson) as Map<String, dynamic>;
      } catch (e) {
        print("Error loading user data: $e");
      }
    }
    
    return {
      'height': 190.0, 
      'age': 20, 
      'gender': 'male', 
    };
  }

  Future<(Map<String, List<double>>, DateTime?, int, double)> loadData(
      Map<String, List<double>> defaultMuscleValues) async {
    final prefs = await SharedPreferences.getInstance();
    final valuesJson = prefs.getString(muscleValuesKey);
    final lastResetStr = prefs.getString(lastResetKey);
    final savedLevel = prefs.getInt(levelKey) ?? 1;
    final savedTotalProgress = prefs.getDouble(totalProgressKey) ?? 0.0;

    Map<String, List<double>> muscleValues = defaultMuscleValues;
    if (valuesJson != null) {
      try {
        final decoded = jsonDecode(valuesJson) as Map<String, dynamic>;
        
        muscleValues = decoded.map((key, value) {
          if (value is List) {
            final List<double> doubleList = value.cast<double>();
            return MapEntry(key, doubleList);
          } else {
            return MapEntry(key, []);
          }
        });
      } catch (e) {
        print("Error loading muscle data: $e");
        muscleValues = defaultMuscleValues;
      }
    }

    final double currentProgress = calculateTotalProgress(muscleValues);
    final int currentLevel = calculateLevel(currentProgress);
    
    DateTime? lastReset = lastResetStr != null ? DateTime.parse(lastResetStr) : null;
    return (muscleValues, lastReset, currentLevel, currentProgress);
  }

  double calculateBMI(double weight, double height) {
    if (height <= 0) return 0;
    return weight / ((height / 100) * (height / 100));
  }

  double calculateBodyFatPercentage({
    required double weight,
    required double height,
    required double waist,
    required double neck,
    required String gender,
    required int age,
    double? hip, // For females
  }) {
    if (height <= 0 || weight <= 0 || waist <= 0 || neck <= 0) return 0;
    
    if (gender.toLowerCase() == 'female') {
      if (hip == null || hip <= 0) return 0;
      // Female formula
      return 495 / (1.29579 - 0.35004 * log(waist + hip - neck) + 0.22100 * log(height)) - 450;
    } else {
      // Male formula
      return 495 / (1.0324 - 0.19077 * log(waist - neck) + 0.15456 * log(height)) - 450;
    }
  }

  String getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Healthy weight';
    if (bmi < 30) return 'Overweight';
    if (bmi < 35) return 'Obesity Class I';
    if (bmi < 40) return 'Obesity Class II';
    return 'Obesity Class III';
  }

  String getBodyFatCategory(double bodyFat, int age, String gender) {
    if (gender.toLowerCase() == 'female') {
      if (age >= 20 && age <= 39) {
        if (bodyFat < 10) return 'Severely Underweight';
        if (bodyFat < 14) return 'Essential';
        if (bodyFat < 21) return 'Athlete';
        if (bodyFat < 25) return 'Fitness';
        if (bodyFat < 32) return 'Average';
        return 'Obese';
      } else if (age >= 40 && age <= 59) {
        if (bodyFat < 10) return 'Severely Underweight';
        if (bodyFat < 14) return 'Essential';
        if (bodyFat < 21) return 'Athlete';
        if (bodyFat < 25) return 'Fitness';
        if (bodyFat < 32) return 'Average';
        return 'Obese';
      } else {
        if (bodyFat < 10) return 'Severely Underweight';
        if (bodyFat < 14) return 'Essential';
        if (bodyFat < 21) return 'Athlete';
        if (bodyFat < 25) return 'Fitness';
        if (bodyFat < 32) return 'Average';
        return 'Obese';
      }
    } else {
      if (age >= 20 && age <= 39) {
        if (bodyFat < 2) return 'Severely Undeweight';
        if (bodyFat < 6) return 'Essential';        
        if (bodyFat < 14) return 'Athlete';
        if (bodyFat < 18) return 'Fitness';
        if (bodyFat < 25) return 'Average';
        return 'Obese';
      } else if (age >= 40 && age <= 59) {
        if (bodyFat < 2) return 'Severely Undeweight';
        if (bodyFat < 6) return 'Essential';        
        if (bodyFat < 14) return 'Athlete';
        if (bodyFat < 18) return 'Fitness';
        if (bodyFat < 25) return 'Average';
        return 'Obese';
      } else {
        if (bodyFat < 2) return 'Severely Undeweight';
        if (bodyFat < 6) return 'Essential';        
        if (bodyFat < 14) return 'Athlete';
        if (bodyFat < 18) return 'Fitness';
        if (bodyFat < 25) return 'Average';
        return 'Obese';
      }
    }
  }

  double calculateTotalProgress(Map<String, List<double>> muscleValues) {
    double total = 0.0;
    muscleValues.forEach((measurement, values) {
      if (values.isNotEmpty) {
        if (measurement == "Weight") {
          final currentWeight = values.last;
          total += (1 - (currentWeight - 85).abs() / 30).clamp(0.0, 1.0) * 100;
        } 
        else if (measurement == "BMI") {
          final currentBMI = values.last;
          total += (1 - (currentBMI - 21.7).abs() / 6.4).clamp(0.0, 1.0) * 100;
        }
        else {
          if (values.length > 1) {
            final avg = values.reduce((a, b) => a + b) / values.length;
            final variance = values.map((v) => pow(v - avg, 2)).reduce((a, b) => a + b) / values.length;
            total += (1 - (variance / (avg + 1))).clamp(0.0, 1.0) * 50;
            
            if (values.last > values.first) {
              total += ((values.last - values.first) / values.first * 10).clamp(0.0, 50);
            }
          } else {
            total += 15; 
          }
        }
      }
    });
    return total;
  }

  int calculateLevel(double totalProgress) {
    if (totalProgress <= 0) return 1;
    
    if (totalProgress < 50) return 1;
    return (log(totalProgress / 50 + 1) / log(2)).floor() + 1;
  }

  double getLevelProgress(double totalProgress, int currentLevel) {
    if (currentLevel <= 1) {
      return totalProgress / 50.0; 
    }
    
    final currentLevelThreshold = 50 * pow(2, currentLevel - 2);
    final nextLevelThreshold = 50 * pow(2, currentLevel - 1);
    
    return (totalProgress - currentLevelThreshold) / (nextLevelThreshold - currentLevelThreshold);
  }

  double getRequiredProgressForNextLevel(int currentLevel, double currentProgress) {
    if (currentLevel < 1) return 50.0;
    
    final nextLevelThreshold = 50 * pow(2, currentLevel - 1);
    final required = nextLevelThreshold - currentProgress;
    return required > 0 ? required : 0.0;
  }
}