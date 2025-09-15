// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:lyfeline/data/creativeStorage.dart';
import 'package:lyfeline/data/atoms.dart';
import 'dart:math';

class CreativeAspectPage extends StatefulWidget {
  const CreativeAspectPage({Key? key}) : super(key: key);

  @override
  CreativeAspectPageState createState() => CreativeAspectPageState();
}

class CreativeAspectPageState extends State<CreativeAspectPage> {
  final Color primaryGreen = Color(0xFF7EE24C);
  final Color darkBackground = Color(0xFF1A1B1E);
  final Color cardBackground = Color(0xFF262626);
  late SharedCreativeStorage storage;
  bool isLoading = true;
  List<Atom> creativeAtoms = [];
  final TextEditingController controller = TextEditingController();
  double creativePoints = 0;
  int currentLevel = 1;
  int totalXp = 0;

  @override
  void initState() {
    super.initState();
    initStorage();
  }

  Future<void> initStorage() async {
    setState(() {
      isLoading = true;
    });
    
    storage = await SharedCreativeStorage.init("creative"); 
    final (loadedAtoms, points, _, level, xp) = await storage.loadData([]);
    
    setState(() {
      creativeAtoms = loadedAtoms;
      creativePoints = points.toDouble();
      currentLevel = level;
      totalXp = xp;
      isLoading = false;
    });
  }

  Future<void> addCreativeAtom() async {
    if (controller.text.isNotEmpty) {
      final newCreativeAtom = Atom(name: controller.text, icon: Icons.favorite);
      setState(() {
        creativeAtoms.add(newCreativeAtom);
        creativePoints = (creativePoints + 5)*1.5; 
      });
      await storage.saveData(creativeAtoms, creativePoints.toInt());
      controller.clear();
    }
  }

  Future<void> removeCreativeAtom(int index) async {
    setState(() {
      creativeAtoms.removeAt(index);
      creativePoints = max(0, creativePoints - 5); 
    });
    await storage.saveData(creativeAtoms, creativePoints.toInt());
  }

  Widget buildLevelCard() {
    final progress = storage.getLevelProgress(creativePoints.toInt(), currentLevel);
    final xpForNextLevel = storage.getXpForNextLevel(creativePoints.toInt(), currentLevel);
    
    return Card(
      color: cardBackground,
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
                      "Creative Level",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Level $currentLevel",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "$creativePoints XP • ${creativeAtoms.length} Projects",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "$currentLevel",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Progress to next level", 
                  style: TextStyle(fontSize: 12, color: Colors.grey)
                ),
                Text(
                  "${(progress * 100).toStringAsFixed(0)}%", 
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              "$xpForNextLevel XP needed for Level ${currentLevel + 1}", 
              style: TextStyle(fontSize: 12, color: Colors.grey)
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1B1E),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1B1E),
        title: Text(
          'Creative Aspect',
          style: TextStyle(
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: isLoading
        ? Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  buildLevelCard(),
                  SizedBox(height: 20),
                  Text(
                    'Your Creative Score:',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    width: 200,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: primaryGreen,
                      child: Text(
                        '$creativePoints',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        backgroundColor: cardBackground,
                        builder: (context) => Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: Container(
                            height: 200,
                            padding: EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Report a creative project:',
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                      )
                                    ),
                                  ]
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: controller,
                                        style: TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          hintText: "Describe what creative thing you did",
                                          hintStyle: TextStyle(color: Colors.grey),
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryGreen,
                                        foregroundColor: Colors.black,
                                      ),
                                      onPressed: addCreativeAtom,
                                      child: Text("Add Creative Atom"),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'There is no great genius without a mixture of madness. ~ Aristotle',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.add),
                    label: Text('Add Creative Atom'),
                  ),
                  SizedBox(height: 16),                  
                  Text(
                    'Your Creative Projects (${creativeAtoms.length})',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  creativeAtoms.isEmpty
                    ? Text(
                        'No creative projects yet!\nAdd your first project to start leveling up.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      )
                    : SizedBox(
                        height: 300,
                        child: ListView.builder(
                          itemCount: creativeAtoms.length,
                          itemBuilder: (context, index) {
                            return Card(
                              color: cardBackground,
                              child: ListTile(
                                title: Text(
                                  creativeAtoms[index].name,
                                  style: TextStyle(color: Colors.white),
                                ), 
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => removeCreativeAtom(index),
                            ),
                          ),
                        );
                      },
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