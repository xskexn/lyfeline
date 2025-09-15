// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:lyfeline/data/academicalStorage.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AcademicalAspectPage extends StatefulWidget {
  const AcademicalAspectPage({Key? key}) : super(key: key);

  @override
  _AcademicalAspectPageState createState() => _AcademicalAspectPageState();
}

class _AcademicalAspectPageState extends State<AcademicalAspectPage> {
  late SharedAcademicStorage storage;

  TextEditingController universityNameController = TextEditingController();
  TextEditingController studentIdController = TextEditingController();
  TextEditingController studentEmailController = TextEditingController();

  String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  Map<String, dynamic> academicalData = {};
  List<String> moduleNames = [];
  bool isLoading = true;

  String university = '';
  String studentId = '';
  String studentEmail = '';

  int currentLevel = 1;
  double levelProgress = 0.0;

  final Map<String, List<String>> termMonths = {
      "Winter Module": ["October", "November", "December"],
      "Spring Module": ["January", "February", "March"],
      "Summer Module": ["April", "May", "June"],
  };

  List<String> getMonthsForTerm(String term) {
    return termMonths[term] ?? ["Month 1", "Month 2", "Month 3"];
  }
    
  Map<String, List<double>> attendanceValues = {
    "Winter Module" : [0,0,0],
    "Spring Module" : [0,0,0],
    "Summer Module" : [0,0,0]
  };

  @override
  void initState() {
    super.initState();
    initStorage();
  }

Future<void> initStorage() async {
  storage = await SharedAcademicStorage.init("academic");
  
  final loadedData = await storage.loadData();
  final loadedModuleNames = await storage.getModuleNames();
  final levelData = await storage.getLevelData();
  
  setState(() {
    academicalData = loadedData;
    moduleNames = loadedModuleNames;
    currentLevel = levelData['level'];
    levelProgress = levelData['progress'];
    isLoading = false;
  });

  await loadUserInfo(); 
  }

  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      university = prefs.getString('university') ?? '';
      studentId = prefs.getString('studentId') ?? '';
      studentEmail = prefs.getString('studentEmail') ?? '';
      
      universityNameController.text = university;
      studentIdController.text = studentId;
      studentEmailController.text = studentEmail;
    });
  }

  //Level Section Moldule
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
                      "Academic Level",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
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
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "$currentLevel",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            LinearProgressIndicator(
              value: levelProgress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
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
          ],
        ),
      ),
    );
  }

  Future<void> refreshLevelData() async {
    final levelData = await storage.getLevelData();
    
    setState(() {
      currentLevel = levelData['level'];
      levelProgress = levelData['progress'];
    });
  }

  //Grade Module
  Future<void> updateModuleName(int index, String newName) async {
    setState(() {
      moduleNames[index] = newName;
    });
    await storage.saveModuleNames(moduleNames);
  }

  Future<void> addGrade(String moduleName, double grade, int weight) async {
    setState(() {
      if (!academicalData['grades'].containsKey(moduleName)) {
        academicalData['grades'][moduleName] = [];
      }
      academicalData['grades'][moduleName].add({
        'grade': grade,
        'weight': weight,
        'date': DateTime.now().toIso8601String()
      });
    });
    await storage.saveData(academicalData);
    refreshLevelData();
  }

  Future<void> showAddGradeDialog() async {
    if (moduleNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please set up module names first"))
      );
      return;
    }

    String selectedModule = moduleNames.first;
    final gradeController = TextEditingController();
    final weightController = TextEditingController(text: "100");

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Add Grade"),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedModule,
                      items: moduleNames.map((module) {
                        return DropdownMenuItem(
                          value: module,
                          child: Text(module),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedModule = value!;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: "Select Module",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: gradeController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Grade",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Weight",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final grade = double.tryParse(gradeController.text);
                    final weight = int.tryParse(weightController.text) ?? 100;
                    if (grade != null && grade >= 0 && grade < 101 && weight > 0 && weight < 101) {
                      Navigator.pop(context, {
                        'module': selectedModule,
                        'grade': grade,
                        'weight': weight
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Please enter valid grade and weight"))
                      );
                    }
                  },
                  child: Text("Add Grade"),
                ),
              ],
            );
          },
        );
      },
    ).then((result) {
      if (result != null) {
        addGrade(result['module'], result['grade'], result['weight']);
      }
    });
  }

  Widget buildGradeOverviewCard(String moduleName, double averageGrade, int assignmentCount, {double width = 600, double height = 400}) {
    
    double progress = averageGrade / 100;

    Widget getFeedbackEmoji(double progress) {
      if (progress < 0.49) {
        return const Text('😕', style: TextStyle(fontSize: 24));
      } else if (progress < 0.69) {
        return const Text('😐', style: TextStyle(fontSize: 24));
      } else if (progress < 0.84){
        return const Text('🤑', style: TextStyle(fontSize: 24));
      } else{
        return const Text('🥵', style: TextStyle(fontSize: 24));
      }
    }

    return SizedBox(
      width: width,
      height: height,
      child: Card.outlined(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 35),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      moduleName,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: const Color.fromARGB(255, 58, 20, 105),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 138, 164, 185)),
                      borderRadius: BorderRadius.circular(90),
                    ),
                  ),
                  const SizedBox(width: 16),
                  getFeedbackEmoji(progress)
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Average Grade: ${averageGrade.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Assignments: $assignmentCount',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double calculateAverageGrade(List<dynamic> grades) {
    if (grades.isEmpty) return 0.0;

    double totalWeightedSum = 0.0;
    double totalWeight = 0.0;

    for (var gradeData in grades) {
      double grade = gradeData['grade'];
      double weight = gradeData['weight'];

      totalWeightedSum += grade * weight;
      totalWeight += weight;
    }

    if (totalWeight <= 0) {
      return 0.0;
    }

    return totalWeightedSum / totalWeight;
  }

  Widget buildGradeCard(String moduleName, double averageGrade, int assignmentCount) {
    return Card(
      child: ListTile(
        title: Text(moduleName),
        subtitle: Text("Average: ${averageGrade.toStringAsFixed(1)}%"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("$assignmentCount assignments"),
            IconButton(
              icon: Icon(Icons.history),
              onPressed: () => showGradeHistory(moduleName),
            ),
          ],
        ),
      ),
    );
  }

  void showGradeHistory(String moduleName) {
    final grades = academicalData['grades'][moduleName] ?? [];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Grade History - $moduleName"),
        content: SizedBox(
          width: 400,
          height: 400,
          child: Column(
            children: [
              ListTile(
                title: Text("Grade", style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text("Weight", style: TextStyle(fontWeight: FontWeight.bold)),
                leading: Text("Date", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: grades.length,
                  itemBuilder: (context, index) {
                    final grade = grades[index];
                    final date = DateTime.parse(grade['date']);
                    return ListTile(
                      title: Text("${grade['grade']}%"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("${grade['weight']}%  "),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text("Delete Grade"),
                                  content: Text("Are you sure you want to delete this grade?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      child: Text("Delete"),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                setState(() {
                                  academicalData['grades'][moduleName].removeAt(index);
                                  if (academicalData['grades'][moduleName].isEmpty) {
                                    academicalData['grades'].remove(moduleName);
                                  }
                                });
                                await storage.saveData(academicalData);
                                Navigator.pop(context); 
                                refreshLevelData();
                              }
                            },
                          ),
                        ],
                      ),
                      leading: Text(DateFormat('MMM dd').format(date)),
                      tileColor: index % 2 == 0 ? Colors.grey.withOpacity(0.1) : null,
                    );
                  },
                ),
              ),
            ],
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

  //Attendance Module
  Future<void> updateAttendance(String term, int monthIndex, double value) async {
    setState(() {
      if (!academicalData['attendance'].containsKey(term)) {
        academicalData['attendance'][term] = [0, 0, 0];
      }
      academicalData['attendance'][term][monthIndex] = value;
    });
    
    await storage.saveData(academicalData);
    refreshLevelData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Attendance record saved!"))
    );
  }

  Future<void> showAddAttendanceDialog() async {
  final terms = academicalData['attendance']?.keys.toList() ?? [];

  if (terms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("No terms available. Please create a term first."))
      );
      return;
  }

  String selectedTerm = terms.first;
  String selectedMonth = getMonthsForTerm(selectedTerm).first;
  final controller = TextEditingController();

  await showDialog(
      context: context,
      builder: (context) {
      return StatefulBuilder(
          builder: (context, setDialogState) {
          return AlertDialog(
              title: Text("Add Attendance Record"),
              content: SizedBox(
              width: 400,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  DropdownButtonFormField<String>(
                      value: selectedTerm,
                      items: terms.map<DropdownMenuItem<String>>((term) {
                      return DropdownMenuItem<String>(
                          value: term,
                          child: Text(term),
                      );
                      }).toList(),
                      onChanged: (value) {
                      setDialogState(() {
                          selectedTerm = value!;
                          selectedMonth = getMonthsForTerm(selectedTerm).first;
                      });
                      },
                      decoration: InputDecoration(
                      labelText: "Select Term",
                      border: OutlineInputBorder(),
                      ),
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                      value: selectedMonth,
                      items: getMonthsForTerm(selectedTerm).map<DropdownMenuItem<String>>((month) {
                      return DropdownMenuItem<String>(
                          value: month,
                          child: Text(month),
                      );
                      }).toList(),
                      onChanged: (value) {
                      setDialogState(() {
                          selectedMonth = value!;
                      });
                      },
                      decoration: InputDecoration(
                      labelText: "Select Month",
                      border: OutlineInputBorder(),
                      ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                      controller: controller,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                      labelText: "Attendance Percentage",
                      suffixText: "%",
                      border: OutlineInputBorder(),
                      ),
                  ),
                  ],
              ),
              ),
              actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
              ),
              ElevatedButton(
                  onPressed: () {
                  final value = double.tryParse(controller.text);
                  if (value != null && value >= 0 && value <= 101) {
                      final monthIndex = getMonthsForTerm(selectedTerm).indexOf(selectedMonth);
                      Navigator.pop(context, {
                      'term': selectedTerm,
                      'monthIndex': monthIndex,
                      'value': value
                      });
                  } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please enter a valid percentage (0-100)"))
                      );
                    }
                  },
                  child: Text("Save"),
              ),
              ],
          );
          },
      );
      },
  ).then((result) {
      if (result != null) {
      updateAttendance(result['term'], result['monthIndex'], result['value']);
      }
  });
  }

  Future<void> removeAttendanceRecord(String attendanceKey, int index) async {
    final bool confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Record?'),
          content: Text('Are you sure you want to delete this record?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete'),
            ),
          ],
        );
      },
    ) ?? false;
    if (confirm) {
      setState(() {
        if (!academicalData['attendance'].containsKey(attendanceKey)) {
          academicalData['attendance'][attendanceKey] = [0, 0, 0];
        }
        academicalData['attendance'][attendanceKey][index] = 0.0;
      });
      await storage.saveData(academicalData);
      refreshLevelData();
    }
  }

  Color getColorForPercentage(double percentage) {
      if (percentage >= 80) return Colors.green;
      if (percentage >= 60) return Colors.orange;
    return Colors.red;
    }

  Widget buildAttendanceSummaryCard() {

    final attendance = academicalData['attendance'] ?? {};
    
    double overallAverage = 0;
    int termCount = 0;
    
    attendance.forEach((term, values) {
        if (values is List && values.length == 3) {
        final termAverage = (values[0] + values[1] + values[2]) / 3;
        overallAverage += termAverage;
        termCount++;
        }
    });
    
    overallAverage = termCount > 0 ? overallAverage / termCount : 0;
    return Card(
        elevation: 4,
        child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
                'Attendance Overview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
                children: [
                Expanded(
                    child: Column(
                    children: [
                        Text(
                        'Overall Average',
                        style: TextStyle(fontSize: 16),
                        ),
                        Text(
                        '${overallAverage.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                    ],
                    ),
                ),
                Expanded(
                    child: Column(
                    children: [
                        Text(
                        'Terms Tracked',
                        style: TextStyle(fontSize: 16),
                        ),
                        Text(
                        '$termCount',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                    ],
                    ),
                ),
                ],
            ),
            SizedBox(height: 16),
            ...attendance.entries.map((entry) {
                final values = entry.value;
                if (values is! List || values.length != 3) return SizedBox();
                
                final termAverage = (values[0] + values[1] + values[2]) / 3;
                return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                    children: [
                    Expanded(
                        flex: 2,
                        child: Text(entry.key, style: TextStyle(color: Colors.greenAccent)),
                    ),
                    Expanded(
                      flex: 5,
                      child: SizedBox(
                        height: 20.0, 
                        child: LinearProgressIndicator(
                          value: termAverage / 100,
                          backgroundColor: const Color.fromARGB(255, 143, 133, 133),
                          borderRadius: BorderRadius.all(Radius.circular(18)),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            getColorForPercentage(termAverage),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                        flex: 1,
                        child: Text('${termAverage.toStringAsFixed(0)}%', style: TextStyle(fontSize: 20, color: Colors.greenAccent)),
                    ),
                    ],
                ),
                );
            }).toList(),
            ],
        ),
        ),
    );
  }

  Widget buildMonthlyAttendanceCard(String term, List<double> values) {
    final monthNames = getMonthsForTerm(term);
    return Card(
        elevation: 4,
        child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
                term,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent),
            ),
            SizedBox(height: 16),
            ...List.generate(3, (index) {
                return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                    children: [
                    Expanded(
                        flex: 2,
                        child: Text(monthNames[index], style: TextStyle(color: Colors.greenAccent),),
                    ),
                    Expanded(
                      flex: 5,
                      child: SizedBox(
                        height: 20.0, 
                        child: LinearProgressIndicator(
                          value: values[index] / 100,
                          backgroundColor: const Color.fromARGB(255, 141, 127, 127),
                          borderRadius: BorderRadius.all(Radius.circular(18)),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            getColorForPercentage(values[index]),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                        flex: 1,
                        child: Text('${values[index].toStringAsFixed(0)}%', style: TextStyle(fontSize: 20, color: Colors.greenAccent)),
                    ),
                    IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => removeAttendanceRecord(term, index),
                    ),
                    ],
                ),
                );
            }),
            SizedBox(height: 8),
            Divider(),
            Row(
                children: [
                Expanded(
                    child: Text(
                    'Term Average',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.greenAccent),
                    ),
                ),
                Text(
                    '${((values[0] + values[1] + values[2]) / 3).toStringAsFixed(1)}%',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.greenAccent),
                ),
                ],
            ),
            ],
        ),
        ),
    );
  }

  void showAddMenuDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Record"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.date_range),
              title: Text("Add Attendance"),
              onTap: () {
                Navigator.pop(context);
                showAddAttendanceDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.grade),
              title: Text("Add Grade"),
              onTap: () {
                Navigator.pop(context);
                showAddGradeDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  //Term Module
  Future<void> addNewTerm(String termName) async {
  setState(() {
    if (!academicalData['attendance'].containsKey(termName)) {
      academicalData['attendance'][termName] = [0, 0, 0];
    }
  });
  
  await storage.saveData(academicalData);
  refreshLevelData();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Term '$termName' added!"))
  );
}

  Future<void> addNewTermDialog() async {
  final termNamecontroller = TextEditingController();
  
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Add New Term"),
        content: TextField(
          controller: termNamecontroller,
          decoration: InputDecoration(
            labelText: "Term Name",
            hintText: "e.g., Fall Term",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final termName = termNamecontroller.text.trim();
              if (termName.isNotEmpty) {
                Navigator.pop(context, termName);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Please enter a term name"))
                );
              }
            },
            child: Text("Add New Term"),
          ),
        ],
      );
    },
  ).then((termName) {
    if (termName != null) {
      addNewTerm(termName);
      }
    });
  }

  void showEditModuleNameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Customize Module Names/Add New Module"),
        content: SizedBox(
          width: 400,
          height: 300,
          child: ListView.builder(
            itemCount: moduleNames.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: TextField(
                  controller: TextEditingController(text: moduleNames[index]),
                  onChanged: (value) => moduleNames[index] = value,
                  decoration: InputDecoration(
                    labelText: "Module ${index + 1}",
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              storage.saveModuleNames(moduleNames);
              Navigator.pop(context);
              setState(() {});
            },
            child: Text("Save Name/Add New Entry"),
          ),
        ],
      ),
    );
  }

  //Student information card
  void addUserInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Student Information"),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: universityNameController,
                decoration: InputDecoration(
                  labelText: "University Name",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: studentIdController,
                decoration: InputDecoration(
                  labelText: "Student ID",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: studentEmailController,
                decoration: InputDecoration(
                  labelText: "Student Email",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('university', universityNameController.text);
              await prefs.setString('studentId', studentIdController.text);
              await prefs.setString('studentEmail', studentEmailController.text);
              
              setState(() {
                university = universityNameController.text.trim();
                studentId = studentIdController.text.trim();
                studentEmail = studentEmailController.text.trim();
              });
              
              Navigator.pop(context);
            },
            child: Text("Save Student Information"),
          ),
        ],
      ),
    );
  }

  Widget buildPersonalCard(String university, String studentId, String studentEmail, {double width = 600, double height = 200}) {
    return SizedBox(
        width: width,
        height: height,
        child: Card.filled(
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Row(
                children: [
                    Text(
                    'University Name: ${university} \nStudent Id: ${studentId} \nStudent Email: ${studentEmail}',
                    style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                    ),
                    ),
                ],
                ),
            ],
            ),
        ),
        ),
    );
    }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    final attendance = academicalData['attendance'] ?? {};
    final grades = academicalData['grades'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academical Aspect'),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: addUserInfoDialog,
            tooltip: "Edit Student Info",
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: addNewTermDialog,
            tooltip: "Add New Term",
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: showEditModuleNameDialog,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 300,
                height: 75,
                child: ElevatedButton.icon(
                  onPressed: () => showAddMenuDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Record', style: TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Attendance', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              buildAttendanceSummaryCard(),
              SizedBox(height: 16),
              ...attendance.entries.map((entry) {
              if (entry.value is List && entry.value.length == 3) {
                  return Column(
                  children: [
                      buildMonthlyAttendanceCard(entry.key, List<double>.from(entry.value)),
                      SizedBox(height: 16),
                    ],
                  );
                }
                return SizedBox();
              }).toList(),

              ...grades.entries.map((entry) {
                final moduleGrades = entry.value;
                final averageGrade = calculateAverageGrade(moduleGrades);
                return buildGradeOverviewCard(
                  entry.key,
                  averageGrade,
                  moduleGrades.length
                );
              }).toList(),

              const SizedBox(height: 20),
              Text('Grades:', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ...grades.entries.map((entry) {
                final moduleGrades = entry.value;
                final averageGrade = calculateAverageGrade(moduleGrades);
                return buildGradeCard(
                  entry.key,
                  averageGrade,
                  moduleGrades.length
                );
              }).toList(),

              if (university.isNotEmpty || studentId.isNotEmpty || studentEmail.isNotEmpty) 
                buildPersonalCard(university, studentId, studentEmail),
              const SizedBox(height: 20),
              buildLevelCard(),
            ],
          ),
        ),
      ),
    );
  }
}
