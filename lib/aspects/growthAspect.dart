// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:lyfeline/data/growthStorage.dart';
import 'package:lyfeline/data/atoms.dart';

class GrowthAspectPage extends StatefulWidget {
  const GrowthAspectPage({Key? key}) : super(key: key);

  @override
  _GrowthAspectPageState createState() => _GrowthAspectPageState();
}

class _GrowthAspectPageState extends State<GrowthAspectPage> {
  List<Atom> growthAtoms = [];
  late SharedGrowthStorage storage;
  bool isLoading = true;
  final TextEditingController atomController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  Set<String> selectedTags = {};

  void showAddGrowthAtomBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '"We can\'t become what we need to be by remaining what we are" - Oprah Winfrey.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            TextField(
              controller: atomController,
              decoration: InputDecoration(
                labelText: 'Add Growth Atom:',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Describe your project (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            
            Text('Select Field:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              children: ['Intellectual', 'Spiritual', 'Physical', 'Literal'].map((tag) {
                return FilterChip(
                  label: Text(tag),
                  selected: selectedTags.contains(tag),
                  selectedColor: Colors.amber,
                  tooltip: "Intellectual: Apprehended Obsidian Concepts\nSpiritual: Bible Study Concepts\nPhysical: New PRs or Sports Achivement\nLiteral: Reading Through Books  ",
                  onSelected: (selected) {
                    setState(() {
                      if (selected && selectedTags.length < 2) {
                        selectedTags.add(tag);
                      } else {
                        selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    resetForm();
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (atomController.text.isNotEmpty && selectedTags.isNotEmpty) {
                      addGrowthAtom();
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Add Growth atom'),
                ),
              ],
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void resetForm() {
    atomController.clear();
    descriptionController.clear();
    selectedTags.clear();
  }

  Future<void> addGrowthAtom() async {
    if (atomController.text.isNotEmpty && selectedTags.isNotEmpty) {
      final newGrowthAtom = Atom(
        name: atomController.text,
        icon: Icons.task,
        tags: List<String>.from(selectedTags),
        description: descriptionController.text
      );
      
      setState(() {
        growthAtoms.add(newGrowthAtom);
      });
      
      await storage.saveData(growthAtoms);
      resetForm(); 
    }
  }

  @override
  void initState() {
    super.initState();
    initStorage();
  }

  Future<void> initStorage() async {
    setState(() {
      isLoading = true;
    });
    
    storage = await SharedGrowthStorage.init("growth"); 
    final (loadedAtoms, _) = await storage.loadData([]); 
    
    setState(() {
      growthAtoms = loadedAtoms;
      isLoading = false;
    });
  }


  Future<void> removeGrowthAtom(int index) async {
    setState(() {
      growthAtoms.removeAt(index);
    });
    await storage.saveData(growthAtoms);
  }

  Future<void> markGrowthProjectCompleted(int index, bool completed) async {
    setState(() {
      growthAtoms[index].isDone = completed;
    });
    
    if (completed) {
      for (String tag in growthAtoms[index].tags) {
        await storage.updateTagCount(tag); 
      }
    }
    
    await storage.saveData(growthAtoms);
  }

  Future<bool> toggleGrowthAtom(int index) async {
    final wasCompleted = growthAtoms[index].isDone;
    await markGrowthProjectCompleted(index, !wasCompleted);
    return growthAtoms[index].isDone;
  }

  Widget buildLevelProgress(){
    return FutureBuilder(
      future: Future.wait([
        storage.getCurrentLevel(),
        storage.getLevelProgress(),
        storage.getTotalXp(),
        storage.getXpForNextLevel(),
        storage.getCompletedProjects()
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text("Error loading level data");
        }
        if (snapshot.hasData) {
          final int level = snapshot.data![0] as int;
          final double progress = snapshot.data![1] as double;
          final int totalXp = snapshot.data![2] as int;
          final int xpForNextLevel = snapshot.data![3] as int;
          final int completedProjects = snapshot.data![4] as int;
          
          return Card(
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
                          Text("Growth Level", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text("Level $level", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text("$totalXp XP • $completedProjects Projects", style: TextStyle(fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "$level",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Progress to next level", style: TextStyle(fontSize: 12)),
                      Text("${(progress * 100).toStringAsFixed(0)}%", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text("$xpForNextLevel XP needed for Level ${level + 1}", 
                    style: TextStyle(fontSize: 12, color: Colors.grey)
                  ),
                ],
              ),
            ),
          );
        }
        return SizedBox.shrink();
      },
    );
  }

  Widget buildTagProgress() {
    return FutureBuilder<Map<String, double>>(
      future: storage.getTagProgress(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error loading tag data"));
        }
        if (snapshot.hasData) {
          final Map<String, double> tagProgress = snapshot.data!;
          
          if (tagProgress.isEmpty) {
            return Center(child: Text("No tags completed yet!"));
          }
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text("Growth Aspects Progress", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: tagProgress.length,
                  itemBuilder: (context, index) {
                    final entry = tagProgress.entries.elementAt(index);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: SizedBox(
                        width: 200, 
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entry.key, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                SizedBox(height: 10),
                                LinearProgressIndicator(value: entry.value),
                                SizedBox(height: 5),
                                Text("${(entry.value * 100).toStringAsFixed(0)}%", style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }
        return SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Growth Aspect"),),
      body: isLoading
        ? Center(child: CircularProgressIndicator())
        : Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          buildLevelProgress(),
          SizedBox(
            child: buildTagProgress()
          ),
          SizedBox(
            width: 300,
            height: 75,
            child: ElevatedButton.icon(
              onPressed: showAddGrowthAtomBottomSheet,
              icon: Icon(Icons.add),
              label: Text("Add Growth Project"),
            ),
          ),
          SizedBox(height: 20),
          Flexible(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Ongoing Projects...', 
                    textAlign: TextAlign.center,  
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: growthAtoms.length,
                      itemBuilder: (context, index) {
                      final growthAtom = growthAtoms[index];
                      return ListTile(
                        leading: Checkbox(
                          value: growthAtom.isDone,
                          onChanged: growthAtom.isDone ? null : (value) => toggleGrowthAtom(index),
                        ),
                        title: Text(growthAtom.name),
                        subtitle: growthAtom.tags.isNotEmpty 
                            ? Text("Tags: ${growthAtom.tags.join(', ')}")
                            : null,
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => removeGrowthAtom(index),
                        ),
                      );
                    },
                  ),
                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}