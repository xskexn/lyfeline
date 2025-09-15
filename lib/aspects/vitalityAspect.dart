import 'package:flutter/material.dart';
import 'package:lyfeline/data/atoms.dart';
import 'package:lyfeline/data/vitalityStorage.dart';
import 'package:intl/intl.dart';

class VitalityAspectPage extends StatefulWidget {
  const VitalityAspectPage({super.key});

  @override
  VitalityAspectPageState createState() => VitalityAspectPageState();
}

class VitalityAspectPageState extends State<VitalityAspectPage> {
  String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  late SharedVitalityStorage storage;

  List<Atom> vitalityAtoms = [
    Atom(name: "Eaten Healthy?", imagePath: "assets/eatingHealthy.png", icon: Icons.menu_book),
    Atom(name: "Drank Enoungh Water?", imagePath: "assets/drinkingWater.png", icon: Icons.fitness_center),
    Atom(name: "Slept On Time/Enough?", imagePath: "assets/sleepingEarly.png", icon: Icons.self_improvement),
    Atom(name: "Moved Around?", imagePath: "assets/movingAround.png", icon: Icons.school),
  ];

  List<Map<String, dynamic>> vitalityRecords = []; 
  int todaysPoints = 0; 

  @override
  void initState() {
    super.initState();
    initData();
  }

  int currentLevel = 1;
  double levelProgress = 0.0;
  int totalDays = 0;
  int totalPoints = 0;

  Future<void> initData() async {
    storage = await SharedVitalityStorage.init("vitality");
    await loadData();
  }

  Future<void> loadData() async {
    final (loadedAtoms, savedPoints, lastReset, savedRecords, loadedLevel, 
          loadedProgress, loadedTotalDays, loadedTotalPoints) = await storage.loadData(vitalityAtoms);

    final now = DateTime.now();
    bool isNewDay = lastReset == null ||
        now.year != lastReset.year ||
        now.month != lastReset.month ||
        now.day != lastReset.day;

    setState(() {
      vitalityAtoms = loadedAtoms;
      vitalityRecords = savedRecords.isNotEmpty ? savedRecords : [];
      todaysPoints = savedPoints;
      currentLevel = loadedLevel;
      levelProgress = loadedProgress;
      totalDays = loadedTotalDays;
      totalPoints = loadedTotalPoints;
    });

    if (isNewDay) {
      finaliseYesterdayPoints();
    }
  }

  void finaliseYesterdayPoints() async {
    final yesterday = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: 1)));
    
    final hasYesterdayRecord = vitalityRecords.any((record) => record['date'] == yesterday);
    
    if (!hasYesterdayRecord && todaysPoints > 0) {
      setState(() {
        vitalityRecords.add({
          'date': yesterday,
          'points': todaysPoints
        });
      });
      
      await storage.finaliseDay(todaysPoints, vitalityRecords);
    }
    
    setState(() {
      for (var vitalityAtom in vitalityAtoms) {
        vitalityAtom.isDone = false;
      }
      todaysPoints = 0;
    });
    
    await storage.saveData(vitalityAtoms, todaysPoints, vitalityRecords);
    
    final levelData = await storage.getLevelData();
    setState(() {
      currentLevel = levelData['level'];
      levelProgress = levelData['progress'];
      totalDays = levelData['totalDays'];
      totalPoints = levelData['totalPoints'];
    });
  }

  void markVitalityAtomDone(int index, bool done) async {
    setState(() {
      vitalityAtoms[index].isDone = done;
      
      if (done && todaysPoints < 8) {
        todaysPoints += 2; 
      } else {
        todaysPoints = todaysPoints > 0 ? todaysPoints -= 2 : 0; 
      }
    });

    if (todaysPoints>=8) todaysPoints+=2; 

    
    await storage.saveData(vitalityAtoms, todaysPoints, vitalityRecords);
  }

  String dailyBounsPoints(){
      return todaysPoints>=8 ? '+2 Bouns Points' : 'No bonus Points Achived';
  }

  void viewPastRecords() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Past Care Records"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: vitalityRecords.length,
            itemBuilder: (context, index) {
              final record = vitalityRecords[index];
              return ListTile(
                title: Text(record['date'] ?? 'Unknown date'),
                trailing: Text("${record['points']} points"),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget buildLevelCard() {
    return Card(
      elevation: 4,
      color: const  Color(0xFF262626),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Vitality Level",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7EE24C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Level $currentLevel",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7EE24C).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "$currentLevel",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7EE24C),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: levelProgress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[700],
              valueColor: const  AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 164, 225, 133)),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              "${(levelProgress * 100).toStringAsFixed(1)}% to level ${currentLevel + 1}",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text("Days: $totalDays", style: const TextStyle(color: Colors.white)),
                Text("Total Points: $totalPoints", style: const TextStyle(color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B1E),
      appBar: AppBar(
        backgroundColor: const  Color(0xFF1A1B1E),
        title: const  Text(
          "Vitality Aspect",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF7EE24C)),
            onPressed: viewPastRecords,
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 700;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Report Your Today, Have You...",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isWide ? 32 : MediaQuery.of(context).size.width * 0.06,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      )
                    ),
                  ),
                  SizedBox(
                    height: isWide ? 500 : MediaQuery.of(context).size.height * 0.6,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWide ? 4 : 1,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1,
                      ),
                      itemCount: vitalityAtoms.length,
                      itemBuilder: (context, index) {
                        final vitalityAtom = vitalityAtoms[index];
                        return GestureDetector(
                          onTapDown: (details) async {
                            final selected = await showMenu(
                              context: context,
                              position: RelativeRect.fromLTRB(
                                details.globalPosition.dx,
                                details.globalPosition.dy,
                                details.globalPosition.dx,
                                details.globalPosition.dy,
                              ),
                              items: const [
                                PopupMenuItem(value: true, child: Text("Mark as Done")),
                                PopupMenuItem(value: false, child: Text("Mark as Not Done"))
                              ],
                            );
                            if (selected != null) {
                              markVitalityAtomDone(index, selected);
                            }
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox( 
                                height: isWide ? 200 : MediaQuery.of(context).size.height * 0.2,
                                width: isWide ? 200 : MediaQuery.of(context).size.width * 0.4,
                                child: Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: vitalityAtom.isDone ? const Color.fromARGB(255, 160, 235, 123) : Colors.grey[800]!,
                                      width: 2,
                                    ),
                                  ),
                                  color: const Color(0xFF262626),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (vitalityAtom.imagePath != null)
                                        Image.asset(
                                          vitalityAtom.imagePath!,
                                          height: isWide ? 150 : MediaQuery.of(context).size.height * 0.15,
                                          width: isWide ? 150 : MediaQuery.of(context).size.width * 0.3,
                                          fit: BoxFit.contain, 
                                        )
                                      else if (vitalityAtom.icon != null)
                                        Icon(
                                          vitalityAtom.icon,
                                          size: isWide ? 50 : MediaQuery.of(context).size.width * 0.1,
                                          color: vitalityAtom.isDone ? const Color.fromARGB(255, 133, 184, 108) : Colors.grey[400],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Text(
                                  vitalityAtom.name,
                                  style: TextStyle(
                                    fontSize: isWide ? 20 : MediaQuery.of(context).size.width * 0.04, 
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF262626),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color:const  Color.fromARGB(255, 168, 234, 135), width: 2),
                          ),
                          child: Text(
                            "Today's Points: $todaysPoints",
                            style: TextStyle(
                              fontSize: isWide ? 24 : MediaQuery.of(context).size.width * 0.04,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            )
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF262626),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: todaysPoints >= 8 ? const Color.fromARGB(255, 145, 212, 111) : Colors.grey[800]!, width: 2),
                          ),
                          child: Text(
                            dailyBounsPoints(),
                            style: TextStyle(
                              fontSize: isWide ? 24 : MediaQuery.of(context).size.width * 0.04,
                              fontWeight: FontWeight.w600,
                              color: todaysPoints >= 8 ? const Color.fromARGB(255, 165, 227, 133) : Colors.grey[400],
                            )
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  buildLevelCard(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}