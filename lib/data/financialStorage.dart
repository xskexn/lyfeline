import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class SharedFinancialStorage {
  final String aspectId;

  SharedFinancialStorage._(this.aspectId);

  static Future<SharedFinancialStorage> init(String aspectId) async {
    return SharedFinancialStorage._(aspectId);
  }

  String get financialValuesKey => "${aspectId}_financialValues";
  String get lastResetKey => "${aspectId}_last_reset";
  String get levelKey => "${aspectId}_level";
  String get totalAmountKey => "${aspectId}_totalAmount";

  Future<void> saveData(Map<String, List<double>> financialValues) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(financialValuesKey, jsonEncode(financialValues));
    await prefs.setString(lastResetKey, DateTime.now().toIso8601String());
    
    final double totalAmount = calculateTotalAmount(financialValues);
    final int level = calculateLevel(totalAmount);
    
    await prefs.setDouble(totalAmountKey, totalAmount);
    await prefs.setInt(levelKey, level);
  }

  Future<(Map<String, List<double>>, DateTime?, int, double)> loadData(
      Map<String, List<double>> defaultFinancialValues) async {
    final prefs = await SharedPreferences.getInstance();
    final valuesJson = prefs.getString(financialValuesKey);
    final lastResetStr = prefs.getString(lastResetKey);
    final savedLevel = prefs.getInt(levelKey) ?? 1;
    final savedTotalAmount = prefs.getDouble(totalAmountKey) ?? 0.0;

    Map<String, List<double>> financialValues = defaultFinancialValues;
    if (valuesJson != null) {
      try {
        final decoded = jsonDecode(valuesJson) as Map<String, dynamic>;
        
        financialValues = decoded.map((key, value) {
          if (value is List) {
            final List<double> doubleList = value.cast<double>();
            return MapEntry(key, doubleList);
          } else {
            return MapEntry(key, [0.0]);
          }
        });
      } catch (e) {
        print("Error loading financial data: $e");
        financialValues = defaultFinancialValues;
      }
    }

    final double currentTotal = calculateTotalAmount(financialValues);
    final int currentLevel = calculateLevel(currentTotal);
    
    DateTime? lastReset = lastResetStr != null ? DateTime.parse(lastResetStr) : null;
    return (financialValues, lastReset, currentLevel, currentTotal);
  }

  double calculateTotalAmount(Map<String, List<double>> financialValues) {
    double total = 0.0;
    financialValues.forEach((account, values) {
      if (values.isNotEmpty) {
        total += values.last; 
      }
    });
    return total;
  }

  int calculateLevel(double totalAmount) {
    if (totalAmount <= 0) return 1;
    
    if (totalAmount < 100) return 1;
    return (log(totalAmount / 100 + 1) / log(2)).floor() + 1;
  }

  double getLevelProgress(double totalAmount, int currentLevel) {
    if (currentLevel <= 1) {
      return totalAmount / 100.0; 
    }
    
    final currentLevelThreshold = 100 * pow(2, currentLevel - 2);
    final nextLevelThreshold = 100 * pow(2, currentLevel - 1);
    
    return (totalAmount - currentLevelThreshold) / (nextLevelThreshold - currentLevelThreshold);
  }

  double getRequiredAmountForLevel(int level) {
    if (level <= 1) return 0.0;
    return (100 * pow(2, level - 2)).toDouble();
  }

  double getRequiredAmountForNextLevel(int currentLevel, double currentAmount) {
    if (currentLevel < 1) return 100.0;
    
    final nextLevelThreshold = 100 * pow(2, currentLevel - 1);
    final required = nextLevelThreshold - currentAmount;
    return required > 0 ? required : 0.0;
  }
}