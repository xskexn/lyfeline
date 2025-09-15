import 'package:flutter/material.dart';
import 'package:lyfeline/data/academicalStorage.dart';
import 'package:lyfeline/data/sharedStorage.dart';
import 'package:lyfeline/data/financialStorage.dart';
import 'package:lyfeline/data/FitnessStorage.dart';
import 'package:lyfeline/data/careStorage.dart';
import 'package:lyfeline/data/vitalityStorage.dart';
import 'package:lyfeline/data/creativeStorage.dart';
import 'package:lyfeline/data/growthStorage.dart';
import 'dart:math';

class HexagonPainter extends CustomPainter {
  final Color fillColor;

  HexagonPainter({required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final double radius = size.width / 2;
    final double h = size.height; 
    final double w = size.width;
    final double centerX = w / 2;
    final double centerY = h / 2;
    
    final points = <Offset>[];
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * pi / 180;
      final x = centerX + radius * cos(angle);
      final y = centerY + radius * sin(angle);
      points.add(Offset(x, y));
    }
    
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < 6; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class SelfPage extends StatefulWidget {
  const SelfPage({Key? key}) : super(key: key);

  @override
  SelfPageState createState() => SelfPageState();
}

class SelfPageState extends State<SelfPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    initStorage();
  }

  Future<void> initStorage() async {
    await userLevels.loadLevels();
    
    await loadFinancialData();
    await loadFitnessData();
    await loadAcademicData();
    await loadCareData();
    await loadVitalityData();
    await loadCreativeData();
    await loadGrowthData();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> loadAcademicData() async {
    try{
      final storage = await SharedAcademicStorage.init("academic");
      final loadedLevelData = await storage.getLevelData();
      final levelData = loadedLevelData['level'];
      final levelProgress = loadedLevelData['progress'];
      
      userLevels.updateLevel('academic', levelData, levelProgress);
    } catch(e) {
        print("Errot loading academic data: $e");
    }
  }

  Future<void> loadCreativeData() async {
    try{
      final storage = await SharedCreativeStorage.init("creative");
      final (loadedAtoms, points, _, level, xp) = await storage.loadData([]);
      final levelData = points.toDouble();
      final levelProgress = xp.toDouble();

      userLevels.updateLevel('creative', levelData, levelProgress);
    } catch(e) {
        print("Errot loading academic data: $e");
    }
  }

  Future<void> loadCareData() async {
    try{
      final storage = await SharedCareStorage.init("care");
      final loadedLevelData = await storage.getLevelData();
      final levelData = loadedLevelData['level'];
      final levelProgress = loadedLevelData['progress'];

      userLevels.updateLevel('care', levelData, levelProgress);
    } catch(e) {
        print("Errot loading care data: $e");
    }
  }

  Future<void> loadVitalityData() async {
    try{
      final storage = await SharedVitalityStorage.init("vitality");
      final loadedLevelData = await storage.getLevelData();
      final levelData = loadedLevelData['level'];
      final levelProgress = loadedLevelData['progress'];

      userLevels.updateLevel('vitality', levelData, levelProgress);
    } catch(e) {
        print("Errot loading vitality data: $e");
    }
  }

  Future<void> loadFinancialData() async {
    try {
      final storage = await SharedFinancialStorage.init("financial");
      final defaultFinancialValues = {
        'Easy-Access Savings': [0.0],
        'Investments': [0.0],
        'Long-Term Savings': [0.0],
        'Emergency Fund': [0.0]
      };
      
      final (loadedValues, loadedLastReset, loadedLevel, loadedTotal) = await storage.loadData(defaultFinancialValues);
      
      final progress = storage.getLevelProgress(loadedTotal, loadedLevel);
      
      userLevels.updateLevel('financial', loadedLevel.toDouble(), progress);
    } catch (e) {
      print("Error loading financial data: $e");
    }
  }

    Future<void> loadGrowthData() async {
    try{
      final storage = await SharedGrowthStorage.init("growth");
      final levelData = await storage.getCurrentLevel();
      final levelProgress = await storage.getLevelProgress();

      userLevels.updateLevel('growth', levelData.toDouble(), levelProgress);
    } catch(e) {
        print("Errot loading growth data: $e");
    }
  }

  Future<void> loadFitnessData() async {
    try {
      final storage = await SharedFitnessStorage.init("fitness");
      final defaultMuscleValues = {
        "Weight": [0.0],
        "BMI": [0.0],
        "Body Fat %": [0.0],
        "Neck": [0.0],
        "Waist": [0.0],
        "Hip": [0.0],
        "Back": [0.0],
        "Chest": [0.0],
        "Right Bicep": [0.0],
        "Left Bicep": [0.0],
        "Right Quad": [0.0],
        "Left Quad": [0.0],
        "Right Calf": [0.0],
        "Left Calf": [0.0]
      };
      
      final (loadedData, lastReset, loadedLevel, loadedProgress) = 
          await storage.loadData(defaultMuscleValues);
      
      final progress = storage.getLevelProgress(loadedProgress, loadedLevel);
      
      userLevels.updateLevel('fitness', loadedLevel.toDouble(), progress);
    } catch (e) {
      print("Error loading fitness data: $e");
    }
  }

  Widget buildCard(String title, double level, double progress, {double width = 270, double height = 250}) {
    return SizedBox(
      width: width,
      height: height,
      child: Card.outlined(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Level ${level.round()}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toStringAsFixed(1)}% to next level',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildGeneralSelfGrade(double height, double width) {  
    String selfGrade;
    Color gradeColor;

    int currentLevel = pow(userLevels.general.round(), 1.5).toInt();
    print(currentLevel);

    if (currentLevel < 50) {
      selfGrade = "D";
      gradeColor = Colors.red;
    } else if (currentLevel < 150) {
      selfGrade = "C";
      gradeColor = Colors.orange;
    } else if (currentLevel < 300) {
      selfGrade = "B";
      gradeColor = Colors.yellow;
    } else if (currentLevel < 500) {
      selfGrade = "A";
      gradeColor = Colors.lightGreen;
    } else if (currentLevel < 1000) {
      selfGrade = "T";
      gradeColor = Colors.blue;
    } else {
      selfGrade = "S";
      gradeColor = Colors.purple;
    }

    return SizedBox(
      width: width, 
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(120, 120), 
            painter: HexagonPainter(fillColor: gradeColor),
          ),
          Text(
            selfGrade,
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 60, 
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('The Self')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('The Self')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isWide = constraints.maxWidth > 700;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 200,
                              width: 200,
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  child: Image.network(
                                    'https://cdn.pfps.gg/pfps/6956-monkey-1.png',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Welcome back Ken!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Your current Level: ${pow(userLevels.general.round(), 1.5).toInt()}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: sqrt(userLevels.generalSelfProgress.clamp(0.0, 1.0)),
                                    minHeight: 12,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 42, 182, 121)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap( children: [
                                  Text(
                                    'Overall Progress: ${(sqrt(userLevels.generalSelfProgress) * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      buildGeneralSelfGrade(160,160)
                                    ]
                                  )
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(
                              child: SizedBox(
                                height: 200,
                                width: 200,
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    child: Image.network(
                                      'https://cdn.pfps.gg/pfps/6956-monkey-1.png',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Welcome back Ken!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your current Level: ${pow(userLevels.general.round(), 1.5).toInt()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32.0),
                              child: LinearProgressIndicator(
                                value: sqrt(userLevels.generalSelfProgress.clamp(0.0, 1.0)),
                                minHeight: 12,
                                backgroundColor: Colors.grey[300],
                                valueColor:  const AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 42, 182, 121)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Overall Progress: ${(sqrt(userLevels.generalSelfProgress) * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            buildGeneralSelfGrade(300,300)
                          ],
                        ),
                        const SizedBox(height: 32),
                        Center(
                        child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          buildCard('Academic', userLevels.academicLevel, userLevels.academicProgress),
                          buildCard('Vitality', userLevels.vitalityLevel, userLevels.vitalityProgress),
                          buildCard('Financial', userLevels.financialLevel, userLevels.financialProgress),
                          buildCard('Care', userLevels.careLevel, userLevels.careProgress),
                          buildCard('Fitness', userLevels.fitnessLevel, userLevels.fitnessProgress),
                          buildCard('Growth', userLevels.growthLevel, userLevels.growthProgress),
                          buildCard('Creative', userLevels.creativeLevel, userLevels.creativeProgress),
                          buildCard('The Self', userLevels.general, userLevels.generalSelfProgress),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}