// ignore_for_file: prefer_const_constructors

//imports
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

//external file pages
import 'aspects/academicalAspect.dart';
import 'aspects/vitalityAspect.dart';
import 'aspects/financialAspect.dart';
import 'aspects/careAspect.dart';
import 'aspects/fitnessAspect.dart';
import 'aspects/growthAspect.dart';
import 'aspects/creativeAspect.dart';
import 'aspects/selfPage.dart';

import 'data/sharedStorage.dart';

void main() {
  runApp(const LyfelineApp());
}

class LyfelineApp extends StatelessWidget {
  const LyfelineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lyfeline',
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF7EE24C), 
          secondary: Color(0xFF7EE24C),
          surface: Color(0xFF1A1B1E),
        ),
        scaffoldBackgroundColor: Color(0xFF1A1B1E),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white, fontFamily: 'Lexend'),
          bodyMedium: TextStyle(color: Colors.white, fontFamily: 'Lexend'),
          titleLarge: TextStyle(color: Colors.white, fontFamily: 'Lexend', fontWeight: FontWeight.w600),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF7EE24C),
            foregroundColor: Colors.black,
            textStyle: TextStyle(
              color: Colors.black,
              fontFamily: 'Lexend',
              fontWeight: FontWeight.w600,
            ),
            alignment: Alignment.center,
          ),
        ),
        useMaterial3: true,
      ),
      home: const HomePage(title: 'Lyfeline'),
    );
  }
}

class RadarChartOverview extends StatelessWidget {

  final double academicProgress;
  final double vitalityProgress;
  final double financialProgress;
  final double careProgress;
  final double fitnessProgress;
  final double growthProgress;
  final double creativeProgress;

  const RadarChartOverview({
    super.key,
    required this.academicProgress,
    required this.vitalityProgress,
    required this.financialProgress,
    required this.careProgress,
    required this.fitnessProgress,
    required this.growthProgress,
    required this.creativeProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1A1B1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: RadarChart(
          RadarChartData(
            radarBackgroundColor: Colors.transparent,
            dataSets: [
              RadarDataSet(
                fillColor: Colors.deepPurple.withOpacity(0.4),
                borderColor: Colors.deepPurple,
                entryRadius: 3,
                dataEntries: [
                  RadarEntry(value: log(academicProgress * 10 + 1) / log(11).clamp(0.0, 1.0)),
                  RadarEntry(value: log(vitalityProgress * 10 + 1) / log(11).clamp(0.0, 1.0)),
                  RadarEntry(value: log(financialProgress * 10 + 1) / log(11).clamp(0.0, 1.0)),
                  RadarEntry(value: log(careProgress * 10 + 1) / log(11).clamp(0.0, 1.0)),
                  RadarEntry(value: log(fitnessProgress * 10 + 1) / log(11).clamp(0.0, 1.0)),
                  RadarEntry(value: log(growthProgress * 10 + 1) / log(11).clamp(0.0, 1.0)),
                  RadarEntry(value: log(creativeProgress * 10 + 1) / log(11).clamp(0.0, 1.0))
                ],
              ),
            ],
            radarShape: RadarShape.polygon,
            titleTextStyle: TextStyle(
              color: Colors.white, 
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            getTitle: (index, angle) {
              final titles = [
                '📚ACADEMICAL',
                '🩸VITALITY',
                '💵FINANCIAL',
                '🫂CARE',
                '🏋🏽FITNESS',
                '📈GROWTH',
                '🎨CREATIVE',
              ];
              return RadarChartTitle(
                text: titles[index],
                angle: angle,
              );
            },
            tickCount: 10, 
            ticksTextStyle: TextStyle(color: Colors.white54, fontSize: 8),
            gridBorderData: BorderSide(color: Colors.white54, width: 1),
            borderData: FlBorderData(show: false), 
          ),
          swapAnimationDuration: Duration(milliseconds: 300),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final int buttonCount = 4;
  List<bool> logged = [false, false, false, false];
  String todayKey = '';
  bool allLeavesCompleted = false;
  int completionStreak = 0;
  DateTime? lastCompletionDate;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    loadLogs();
    loadCompletionData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (today != todayKey) {
      setState(() {
        todayKey = today;
        logged = List.filled(buttonCount, false);
        allLeavesCompleted = false;
      });
      loadLogs();
    }
  }

  Future<void> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final logs = prefs.getStringList(todayKey);
    setState(() {
      if (logs != null && logs.length == buttonCount) {
        logged = logs.map((e) => e == '1').toList();
        checkAllLeavesCompleted();
      } else {
        logged = List.filled(buttonCount, false);
      }
    });
  }

  Future<void> loadCompletionData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      completionStreak = prefs.getInt('completion_streak') ?? 0;
      final lastDateStr = prefs.getString('last_completion_date');
      lastCompletionDate = lastDateStr != null ? DateTime.parse(lastDateStr) : null;
    });
  }

  Future<void> refreshData() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      await loadLogs();
      await loadCompletionData();
      
      todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      if (today != todayKey) {
        logged = List.filled(buttonCount, false);
        allLeavesCompleted = false;
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> logEntry(int index) async {
    if (logged[index]) return;
    
    setState(() {
      logged[index] = true;
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      todayKey,
      logged.map((e) => e ? '1' : '0').toList(),
    );
    
    checkAllLeavesCompleted();
  }

  void checkAllLeavesCompleted() {
    if (logged.every((element) => element) && !allLeavesCompleted) {
      allLeavesCompleted = true;
      celebrateCompletion();
      updateCompletionStreak();
    }
  }

  Future<void> updateCompletionStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final yesterday = today.subtract(Duration(days: 1));
    
    if (lastCompletionDate != null && 
        lastCompletionDate!.year == yesterday.year &&
        lastCompletionDate!.month == yesterday.month &&
        lastCompletionDate!.day == yesterday.day) {
      completionStreak++;
    } else if (lastCompletionDate == null || lastCompletionDate!.isBefore(yesterday)) {
      completionStreak = 1;
    }
    
    await prefs.setInt('completion_streak', completionStreak);
    await prefs.setString('last_completion_date', today.toIso8601String());
    
    setState(() {});
  }

  void celebrateCompletion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A1B1E),
          title: Text(
            '🍃 All leaves Watered!',
            style: TextStyle(color: Color(0xFF7EE24C), fontWeight: FontWeight.bold),
          ),
          content: Text(
            'You\'ve completed all 4 leaves today!\n\nCurrent streak: $completionStreak days',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Continue!',
                style: TextStyle(color: Color(0xFF7EE24C)),
              ),
            ),
          ],
        );
      },
    );
  }

  String getGreeting() {
    var hour = DateTime.now().hour;

    if (hour < 12) {
      return '☀️ Good morning, Ken!';
    } else if (hour < 17) {
      return '🍝 Good afternoon, Ken!';
    } else {
      return '🌜 Good evening, Ken!';
    }
  }

  String getDate() {
    final now = DateTime.now();
    return DateFormat('EEEE, MMMM d, y').format(now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: refreshData,
        child: isLoading 
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 2,
              ),
            )
          : Icon(Icons.refresh),
      ),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isWide = constraints.maxWidth > 700; 
            Widget mainContent = isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      height: 300,
                      width: 300,
                      child: RadarChartOverview(
                      academicProgress: userLevels.academicProgress,
                      vitalityProgress: userLevels.vitalityProgress,
                      financialProgress: userLevels.financialProgress,
                      careProgress: userLevels.careProgress,
                      fitnessProgress: userLevels.fitnessProgress,
                      growthProgress: userLevels.growthProgress,
                      creativeProgress: userLevels.creativeProgress,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(child: buildRightSide(isWide)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 280, 
                    child: RadarChartOverview(
                      academicProgress: userLevels.academicProgress,
                      vitalityProgress: userLevels.vitalityProgress,
                      financialProgress: userLevels.financialProgress,
                      careProgress: userLevels.careProgress,
                      fitnessProgress: userLevels.fitnessProgress,
                      growthProgress: userLevels.growthProgress,
                      creativeProgress: userLevels.creativeProgress,
                    ),
                  ),
                  const SizedBox(height: 16),
                  buildRightSide(isWide),
                ],
              );

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  mainContent,
                  const SizedBox(height: 32),
                  buildBottomMenu(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildRightSide(bool isWide) {
    return Column(
      crossAxisAlignment: isWide ? CrossAxisAlignment.end : CrossAxisAlignment.center,
      children: [
        Text(
          getGreeting(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 32,
            color: Color.fromARGB(255, 0, 217, 255),
            fontFamily: 'Lexend',
          ),
        ),
        Text(
          getDate(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color.fromARGB(255, 0, 217, 255),
            fontFamily: 'Lexend',
          ),
        ),
        if (completionStreak > 0) ...[
          SizedBox(height: 8),
          Text(
            '🔥 $completionStreak day streak',
            style: TextStyle(
              fontSize: 16,
              color: Colors.amber,
              fontFamily: 'Lexend',
            ),
          ),
        ],
        const SizedBox(height: 16),
        isWide
        ? Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              buildButtonColumn(0, 1),
              const SizedBox(width: 12),
              buildButtonColumn(2, 3),
              const SizedBox(width: 12),
              buildPieChart(),
            ],
          )
        : Column(
            children: [
              buildButtonColumn(0, 1),
              const SizedBox(height: 12),
              buildButtonColumn(2, 3),
              const SizedBox(height: 12),
              buildPieChart(),
          ],
        ),
      ],
    );
  }

  Widget buildButtonColumn(int idx1, int idx2) {
    return Column(
      children: [
        SizedBox(
          height: 60,
          width: 180,
          child: ElevatedButton(
            onPressed: logged[idx1] ? null : () => logEntry(idx1),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF7EE24C),
              foregroundColor: Colors.black,
              disabledBackgroundColor:  Color.fromARGB(255, 0, 128, 11).withOpacity(0.5),
              disabledForegroundColor: Colors.black.withOpacity(0.5),
            ),
            child: Text(
              idx1 == 0
                  ? 'Physical Leaf'
                  : idx1 == 1
                      ? 'Accountability Leaf'
                      : idx1 == 2
                          ? 'Knowledge Leaf'
                          : 'Spiritual Leaf',
                          textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontFamily: 'Lexend'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          width: 180,
          child: ElevatedButton(
            onPressed: logged[idx2] ? null : () => logEntry(idx2),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF7EE24C),
              foregroundColor: Colors.black,
              disabledBackgroundColor: Color.fromARGB(255, 0, 128, 11).withOpacity(0.5),
              disabledForegroundColor: Colors.black.withOpacity(0.5),
            ),
            child: Text(
              idx2 == 0
                  ? 'Physical Leaf'
                  : idx2 == 1
                      ? 'Accountability Leaf'
                      : idx2 == 2
                          ? 'Knowledge Leaf'
                          : 'Spiritual Leaf',
                          textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontFamily: 'Lexend'),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildBottomMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
              Expanded(
              child: SizedBox(
                height: 90,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AcademicalAspectPage()),
                    );
                  },
                  child: const Text('📔 Academic Aspect', textAlign: TextAlign.center ,style: TextStyle(fontSize: 25)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 90,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => VitalityAspectPage()),
                    );
                  },
                  child: const Text('🩸 Vitality Aspect', textAlign: TextAlign.center ,style: TextStyle(fontSize: 25)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 90,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FinancialAspectPage()),
                    );
                  },
                  child: const Text('💰 Financial Aspect', textAlign: TextAlign.center, style: TextStyle(fontSize: 25)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 90,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CareAspectPage()),
                    );
                  },
                  child: const Text('🧑🏽 Care Aspect', textAlign: TextAlign.center, style: TextStyle(fontSize: 25)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 90,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FitnessAspectPage()),
                    );
                  },
                  child: const Text('🏋🏽 Fitness Aspect', textAlign: TextAlign.center, style: TextStyle(fontSize: 25)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 90,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GrowthAspectPage()),
                    );
                  },
                  child: const Text('⚡ Growth Aspect', textAlign: TextAlign.center, style: TextStyle(fontSize: 25)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 90,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => CreativeAspectPage()));
                  },
                  child: const Text('⚒️ Creative Aspect', textAlign: TextAlign.center, style: TextStyle(fontSize: 25)),
                )
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 90,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SelfPage()),
                    );
                  },
                  child: const Text('💫 The Self', textAlign: TextAlign.center, style: TextStyle(fontSize: 25)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildPieChart() {
    return SizedBox(
      height: 120,
      width: 120,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: logged[0] ? 1.0 : 0.0,
              color: Colors.deepPurple,
              title: logged[0] ? '💪🏽' : '',
              titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              radius: 20,
            ),
            PieChartSectionData(
              value: logged[1] ? 1.0 : 0.0,
              color: Colors.blue,
              title: logged[1] ? '🫵🏽' : '',
              titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              radius: 20,
            ),
            PieChartSectionData(
              value: logged[2] ? 1.0 : 0.0,
              color: Colors.green,
              title: logged[2] ? '📔' : '',
              titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              radius: 20,
            ),
            PieChartSectionData(
              value: logged[3] ? 1.0 : 0.0,
              color: Colors.orange,
              title: logged[3] ? '🙏🏽' : '',
              titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              radius: 20,
            ),
          ],
          sectionsSpace: 2, 
          centerSpaceRadius: 30,
        ),
      ),
    );
  }
}