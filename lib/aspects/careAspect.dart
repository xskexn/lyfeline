// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:lyfeline/data/atoms.dart';
import 'package:intl/intl.dart';
import 'package:lyfeline/data/careStorage.dart';

class CareAspectPage extends StatefulWidget {
  const CareAspectPage({super.key});

  @override
  CareAspectPageState createState() => CareAspectPageState();
}


class CareAspectPageState extends State<CareAspectPage> {
  late SharedCareStorage storage;
  String today = DateFormat('yyyy-MM-dd').format(DateTime.now());


  List<Atom> careAtoms = [
    Atom(name: "Taken Care Of Your Space?", imagePath: "assets/careSpace.png", icon: Icons.home),
    Atom(name: "Taken Care Of Your Skin & Face?", imagePath: "assets/careSkinBody.png", icon: Icons.boy_rounded),
    Atom(name: "Taken Care of Your Loved Ones?", imagePath: "assets/socialCare.png", icon: Icons.people_alt),
    Atom(name: "Taken Care of Your Mind?", imagePath: "assets/selfCare.png", icon: Icons.emoji_emotions),
  ];

  int currentLevel = 1;
  double levelProgress = 0.0;
  int totalDays = 0;
  int totalPoints = 0;

  List<Map<String, dynamic>> careRecords = []; 
  int todaysPoints = 0; 

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData() async {
    storage = await SharedCareStorage.init("care");
    await loadData();
  }

Future<void> loadData() async {
  final (loadedAtoms, savedPoints, lastReset, savedRecords, loadedLevel, loadedProgress, loadedTotalDays, loadedTotalPoints) = await storage.loadData(careAtoms);

    final now = DateTime.now();
    bool isNewDay = lastReset == null ||
        now.year != lastReset.year ||
        now.month != lastReset.month ||
        now.day != lastReset.day;

    setState(() {
      careAtoms = loadedAtoms;
      careRecords = savedRecords ?? [];
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
    
    final hasYesterdayRecord = careRecords.any((record) => record['date'] == yesterday);
    
    if (!hasYesterdayRecord && todaysPoints > 0) {
      setState(() {
        careRecords.add({
          'date': yesterday,
          'points': todaysPoints
        });
      });
      
      await storage.finaliseDay(todaysPoints, careRecords);
    }
    
    setState(() {
      for (var careAtom in careAtoms) {
        careAtom.isDone = false;
      }
      todaysPoints = 0;
    });
    
    await storage.saveData(careAtoms, todaysPoints, careRecords);
    
    final levelData = await storage.getLevelData();
    setState(() {
      currentLevel = levelData['level'];
      levelProgress = levelData['progress'];
      totalDays = levelData['totalDays'];
      totalPoints = levelData['totalPoints'];
    });
  }

  void markCareAtomDone(int index, bool done) async {
    setState(() {
      careAtoms[index].isDone = done;
      
      if (done && todaysPoints < 8) {
        todaysPoints += 2; 
      } else {
        todaysPoints = todaysPoints > 0 ? todaysPoints -= 2 : 0; 
      }
    });

    if (todaysPoints>=8) todaysPoints+=2; 

    
    await storage.saveData(careAtoms, todaysPoints, careRecords);
  }

  String dailyBounsPoints(){
      return todaysPoints>=8 ? '+2 Bouns Points' : 'No bonus Points Achived';
  }

  void viewPastRecords() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Past Care Records"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: careRecords.length,
            itemBuilder: (context, index) {
              final record = careRecords[index];
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
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget buildLevelCard() {
    return Card(
      elevation: 4,
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
                    Text(
                      "Care Level",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Level $currentLevel",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "$currentLevel",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            LinearProgressIndicator(
              value: levelProgress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            SizedBox(height: 8),
            Text(
              "${(levelProgress * 100).toStringAsFixed(1)}% to level ${currentLevel + 1}",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text("Days: $totalDays"),
                Text("Total Points: $totalPoints"),
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
      appBar: AppBar(
        title: const Text("Care Aspect"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
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
                      "Report Your Today, Have You..,",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isWide ? 40 : MediaQuery.of(context).size.width * 0.08,
                        fontWeight: FontWeight.bold
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
                      itemCount: careAtoms.length,
                      itemBuilder: (context, index) {
                        final careAtom = careAtoms[index];
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
                              markCareAtomDone(index, selected);
                            }
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox( 
                                height: isWide ? 200 : MediaQuery.of(context).size.height * 0.2,
                                width: isWide ? 200 : MediaQuery.of(context).size.width * 0.4,
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  color: careAtom.isDone ? Colors.green[100] : Colors.white,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (careAtom.imagePath != null)
                                        Image.asset(
                                          careAtom.imagePath!,
                                          height: isWide ? 150 : MediaQuery.of(context).size.height * 0.15,
                                          width: isWide ? 150 : MediaQuery.of(context).size.width * 0.3,
                                          fit: BoxFit.contain,
                                        )
                                      else if (careAtom.icon != null)
                                        Icon(
                                          careAtom.icon,
                                          size: isWide ? 50 : MediaQuery.of(context).size.width * 0.1,
                                          color: careAtom.isDone ? Colors.green : Colors.black54,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Text(
                                  careAtom.name,
                                  style: TextStyle(
                                    fontSize: isWide ? 20 : MediaQuery.of(context).size.width * 0.04,
                                    fontWeight: FontWeight.w800,
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
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Color(0xFF262626),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Color(0xFF7EE24C), width: 2),
                          ),
                          child: Text(
                            "Today's Points: $todaysPoints",
                            style: TextStyle(
                              fontSize: isWide ? 24 : MediaQuery.of(context).size.width * 0.04,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'SF Pro Display',
                            )
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Color(0xFF262626),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: todaysPoints >= 8 ? Color(0xFF7EE24C) : Colors.grey[800]!, width: 2),
                          ),
                          child: Text(
                            dailyBounsPoints(),
                            style: TextStyle(
                              fontSize: isWide ? 24 : MediaQuery.of(context).size.width * 0.04,
                              fontWeight: FontWeight.w600,
                              color: todaysPoints >= 8 ? Color(0xFF7EE24C) : Colors.grey[400],
                              fontFamily: 'SF Pro Display',
                            )
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20), 
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