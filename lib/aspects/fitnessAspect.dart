import 'package:flutter/material.dart';
import 'package:lyfeline/data/fitnessStorage.dart';
import 'package:intl/intl.dart';
import 'dart:math'; 

class FitnessAspectPage extends StatefulWidget {
  const FitnessAspectPage({Key? key}) : super(key: key);

  @override
  _FitnessAspectPageState createState() => _FitnessAspectPageState();
}

class _FitnessAspectPageState extends State<FitnessAspectPage> {
  Map<String, List<double>> muscleValues = {
    "Weight": [0],
    "BMI": [0],
    "Body Fat %": [0],
    "Neck": [0],
    "Waist": [0],
    "Hip": [0],
    "Back": [0],
    "Chest": [0],
    "Right Bicep": [0],
    "Left Bicep": [0],
    "Right Quad": [0],
    "Left Quad": [0],
    "Right Calf": [0],
    "Left Calf": [0]
  };
  late SharedFitnessStorage storage;
  bool isLoading = true;
  String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  int currentLevel = 1;
  double totalProgress = 0.0;
  
  Map<String, dynamic> userData = { //Peronsal Default values
    'height': 190.0,
    'age': 20,
    'gender': 'male',
  };

  Future<void> initStorage() async {
    storage = await SharedFitnessStorage.init("fitness");
    
    final Map<String, List<double>> defaultMuscleValues = {
      "Weight": [0],
      "BMI": [0],
      "Body Fat %": [0],
      "Neck": [0],
      "Waist": [0],
      "Hip": [0],
      "Back": [0],
      "Chest": [0],
      "Right Bicep": [0],
      "Left Bicep": [0],
      "Right Quad": [0],
      "Left Quad": [0],
      "Right Calf": [0],
      "Left Calf": [0]
    };
    
    final (loadedData, lastReset, loadedLevel, loadedProgress) = await storage.loadData(defaultMuscleValues);
    final loadedUserData = await storage.loadUserData();
    
    setState(() {
      muscleValues = loadedData;
      currentLevel = loadedLevel;
      totalProgress = loadedProgress;
      userData = loadedUserData;
      isLoading = false; 
    });
  }

  Future<void> updateUserData() async {
    final heightController = TextEditingController(text: userData['height'].toString());
    final ageController = TextEditingController(text: userData['age'].toString());
    String selectedGender = userData['gender'];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Update Personal Information"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: heightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Height (cm)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text("Gender: "),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: selectedGender,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedGender = newValue!;
                          });
                        },
                        items: <String>['male', 'female']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value[0].toUpperCase() + value.substring(1)),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final height = double.tryParse(heightController.text) ?? userData['height'];
                  final age = int.tryParse(ageController.text) ?? userData['age'];
                  
                  setState(() {
                    userData = {
                      'height': height,
                      'age': age,
                      'gender': selectedGender,
                    };
                  });
                  
                  storage.saveUserData(userData);
                  calculateBMIAndBodyFat();
                  Navigator.pop(context);
                },
                child:const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void calculateBMIAndBodyFat() {
    final weight = muscleValues['Weight']?.last ?? 0;
    final height = userData['height'] ?? 170.0;
    final waist = muscleValues['Waist']?.last ?? 0;
    final neck = muscleValues['Neck']?.last ?? 0;
    final hip = muscleValues['Hip']?.last;
    final age = userData['age'] ?? 30;
    final gender = userData['gender'] ?? 'male';
    
    final bmi = storage.calculateBMI(weight, height);
    
    final bodyFat = storage.calculateBodyFatPercentage(
      weight: weight,
      height: height,
      waist: waist,
      neck: neck,
      hip: hip,
      gender: gender,
      age: age,
    );
    
    setState(() {
      if (muscleValues['BMI']!.isEmpty) {
        muscleValues['BMI'] = [bmi];
      } else {
        muscleValues['BMI']!.add(bmi);
      }
      
      if (muscleValues['Body Fat %']!.isEmpty) {
        muscleValues['Body Fat %'] = [bodyFat];
      } else {
        muscleValues['Body Fat %']!.add(bodyFat);
      }
    });
    
    storage.saveData(muscleValues);
  }

  Widget buildLevelCard() {
    final progress = storage.getLevelProgress(totalProgress, currentLevel);
    final nextLevelProgress = storage.getRequiredProgressForNextLevel(currentLevel, totalProgress);
    
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
                      "Overall Fitness Level",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Level $currentLevel",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Progress: ${totalProgress.toStringAsFixed(1)}",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "$currentLevel",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(const Color.fromARGB(255, 88, 203, 126)),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              "${nextLevelProgress.toStringAsFixed(1)} progress to level ${currentLevel + 1}",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHealthCard({
    required String title,
    required double currentValue,
    required String category,
    Color categoryColor = Colors.green,
  }) {
    return SizedBox(
      width: 180,
      height: 160,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(137, 104, 215, 171),
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                  ),
                  children: [
                    TextSpan(text: currentValue.toStringAsFixed(1)),
                    if (title == 'BMI')
                      const TextSpan(
                        text: " kg/m²",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.lightGreenAccent),
                      )
                    else
                      const TextSpan(
                        text: " %",
                        style: TextStyle(fontSize: 20,  fontWeight: FontWeight.normal, color: Colors.lightGreenAccent, ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: categoryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    initStorage();
  }

  Future<void> addMuscleDialog({
    required String muscleType,
    String? muscleType2,
    String? muscleHintText1,
    String? muscleHintText2,
  }) async {
    final Map<String, double>? muscleAtoms = await showDialog<Map<String, double>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final controller1 = TextEditingController();
        final controller2 = TextEditingController();

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: Text('Add record for $muscleType'),
          content: StatefulBuilder(
            builder: (context, dialogSetState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          muscleType,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: controller1,
                            decoration: InputDecoration(
                              hintText: muscleHintText1 ?? 'Enter value',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (muscleType2 != null)
                      Row(
                        children: [
                          Text(
                            muscleType2,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: controller2,
                              decoration: InputDecoration(
                                hintText: muscleHintText2 ?? 'Enter value',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final text1 = controller1.text.trim();
                final text2 = controller2.text.trim();

                if (text1.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a value for the first muscle field')),
                  );
                  return;
                }

                final Map<String, double> values = {
                  muscleType: double.tryParse(text1) ?? 0.0,
                };

                if (muscleType2 != null && text2.isNotEmpty) {
                  values[muscleType2] = double.tryParse(text2) ?? 0.0;
                }

                Navigator.of(dialogContext).pop(values);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (muscleAtoms != null) {
      setState(() {
        muscleAtoms.forEach((key, value) {
          if (muscleValues.containsKey(key)) {
            muscleValues[key]!.add(value);
          } else {
            muscleValues[key] = [value];
          }
        });
      });

      await storage.saveData(muscleValues);
      
      if (muscleAtoms.containsKey('Weight') || muscleAtoms.containsKey('Waist') || muscleAtoms.containsKey('Neck')) {
        calculateBMIAndBodyFat();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record saved')),
      );
    }
  }

  Future<void> updateMuscleRecord(String muscleKey, int index) async {
    final controller = TextEditingController();
    final currentValue = muscleValues[muscleKey]![index].toString();

    controller.text = currentValue;

    final double? newValue = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update $muscleKey'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'New value',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(controller.text);
                if (value != null) {
                  Navigator.pop(context, value);
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    if (newValue != null) {
      setState(() {
        muscleValues[muscleKey]![index] = newValue;
      });
      await storage.saveData(muscleValues);
    }
  }

  Future<void> removeMuscleRecord(String muscleKey, int index) async {
    final bool confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Record?'),
          content: const Text('Are you sure you want to delete this record?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      setState(() {
        muscleValues[muscleKey]!.removeAt(index);
        if (muscleValues[muscleKey]!.isEmpty) {
          muscleValues[muscleKey]!.add(0.0);
        }
      });
      await storage.saveData(muscleValues);
    }
  }

  Widget muscleDisplayButton({
    required String title,
    required String muscleType,
    required String muscleHintText1,
    String? muscleType2,
    String? muscleHintText2,
  }) {
    return SizedBox(
      height: 30,
      width: 170,
      child: ElevatedButton(
        onPressed: () {
          addMuscleDialog(
            muscleType: muscleType,
            muscleType2: muscleType2,
            muscleHintText1: muscleHintText1,
            muscleHintText2: muscleHintText2,
          );
        },
        child: Text(title),
      ),
    );
  }

  Widget buildFitnessCard({
    required String title,
    required double currentValue,
    required double valueChange, 
    double width = 180,
    double height = 160,
  }) {

    return SizedBox(
      width: width,
      height: height,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(137, 104, 215, 171),
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                  ),
                  children: [
                    TextSpan(text: currentValue.toStringAsFixed(1)),
                    const TextSpan(
                      text: " kg/cm",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal, color: Colors.lightGreenAccent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    calculateChange(muscleValues[title] ?? [0.0]) > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 16,
                    color: calculateChange(muscleValues[title] ?? [0.0]) > 0 ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    valueChange.abs().toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: calculateChange(muscleValues[title] ?? [0.0]) > 0 ? Colors.green : Colors.red,
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

  double calculateChange(List<double> values) {
    if (values.length < 2) return 0.0;
        double difference = values.last - values[values.length - 2];
    return difference;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator()); 
    }

    final bmi = muscleValues['BMI']?.last ?? 0;
    final bodyFat = muscleValues['Body Fat %']?.last ?? 0;
    final bmiCategory = storage.getBMICategory(bmi);
    final bodyFatCategory = storage.getBodyFatCategory(
      bodyFat, 
      userData['age'] ?? 20, 
      userData['gender'] ?? 'male'
    );

    final bmiColor = bmiCategory.contains('Healthy Weight') ? Colors.green : bmiCategory.contains('Overweight') ? Colors.orange : Colors.red;
                    
    final bodyFatColor = bodyFatCategory.contains('Athlete') ? Colors.green : bodyFatCategory.contains('Fitness') ? Colors.orange : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Aspect'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: updateUserData,
            tooltip: "Update Personal Info",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  buildLevelCard(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildHealthCard(
                        title: 'BMI', 
                        currentValue: bmi,
                        category: bmiCategory,
                        categoryColor: bmiColor,
                      ),
                      const SizedBox(width: 15),
                      buildHealthCard(
                        title: 'Body Fat %', 
                        currentValue: bodyFat,
                        category: bodyFatCategory,
                        categoryColor: bodyFatColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 55,
                        width: 300,
                        child: ElevatedButton.icon(
                          onPressed: (){
                             showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  title: const Text("Create/View Record", textAlign: TextAlign.center, style: TextStyle(fontSize: 22)),
                                  content: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                    SizedBox(
                                      width: 300, 
                                      height: 75,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                            ),
                                            builder: (context) => Padding(
                                              padding: EdgeInsets.only(
                                                bottom: MediaQuery.of(context).viewInsets.bottom,
                                              ),
                                              child: SizedBox(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      children: [
                                                      muscleDisplayButton(
                                                        title: 'Back', 
                                                        muscleType: 'Back', 
                                                        muscleHintText1: 'Measure the width of your back'
                                                      ),
                                                      const SizedBox(width: 8),
                                                      muscleDisplayButton(
                                                        title: 'Chest', 
                                                        muscleType: 'Chest', 
                                                        muscleHintText1: 'Measure the length of your chest'
                                                      )
                                                    ]),
                                                    const SizedBox(height: 10),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      children: [
                                                      muscleDisplayButton(
                                                        title: 'Biceps', 
                                                        muscleType: 'Right Bicep', 
                                                        muscleHintText1: 'Right bicep circumference',
                                                        muscleType2: 'Left Bicep', 
                                                        muscleHintText2: 'Left bicep circumference'
                                                      ),
                                                      const SizedBox(width: 8),
                                                      muscleDisplayButton(
                                                        title: 'Quads', 
                                                        muscleType: 'Right Quad', 
                                                        muscleHintText1: 'Right quad circumference',
                                                        muscleType2: 'Left Quad', 
                                                        muscleHintText2: 'Left quad circumference'
                                                      ),
                                                    ]),
                                                    const SizedBox(height: 10),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      children: [
                                                      muscleDisplayButton(
                                                        title: 'Calf Muscles', 
                                                        muscleType: 'Right Calf', 
                                                        muscleHintText1: 'Right calf circumference',
                                                        muscleType2: 'Left Calf', 
                                                        muscleHintText2: 'Left calf circumference'
                                                      ),
                                                      const SizedBox(width: 8),
                                                      muscleDisplayButton(
                                                        title: 'Neck', 
                                                        muscleType: 'Neck', 
                                                        muscleHintText1: 'Neck circumference'
                                                      ),
                                                    ]),
                                                    const SizedBox(height: 10),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      children: [
                                                      muscleDisplayButton(
                                                        title: 'Weight', 
                                                        muscleType: 'Weight', 
                                                        muscleHintText1: 'Add your weight'
                                                      ),
                                                      const SizedBox(width: 8),
                                                      muscleDisplayButton(
                                                        title: 'Waist', 
                                                        muscleType: 'Waist', 
                                                        muscleHintText1: 'Waist measurement'
                                                      ),
                                                    ]),
                                                    const SizedBox(height: 10),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      children: [
                                                      muscleDisplayButton(
                                                        title: 'Hip', 
                                                        muscleType: 'Hip', 
                                                        muscleHintText1: 'Hip measurement'
                                                      ),
                                                    ]),
                                                    const SizedBox(height: 16),
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context),
                                                      child: const Text('Close'),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.add), 
                                        label: const Text('Create Record', style: TextStyle(fontSize: 16)),
                                      ),
                                    ),
                                    const SizedBox(height: 22),
                                    SizedBox(
                                      width: 300,
                                      height: 75,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20.0),
                                                ),
                                                title: const Text("Past Records"),
                                                content: SizedBox(
                                                  height: 400,
                                                  width: double.maxFinite,
                                                  child: ListView.builder(
                                                    itemCount: muscleValues.length,
                                                    itemBuilder: (context, index) {
                                                      final muscleKey = muscleValues.keys.elementAt(index);
                                                      final values = muscleValues[muscleKey]!;
                                                      
                                                      return ExpansionTile(
                                                        title: Text(muscleKey),
                                                        children: values.asMap().entries.map((entry) {
                                                          final valueIndex = entry.key;
                                                          final value = entry.value;
                                                          
                                                          return ListTile(
                                                            title: Text(value.toStringAsFixed(2)),
                                                            subtitle: Text('Measurement ${valueIndex + 1}, $today'),
                                                            trailing: Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                IconButton(
                                                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                                                  onPressed: () => updateMuscleRecord(muscleKey, valueIndex),
                                                                ),
                                                                IconButton(
                                                                  icon: const Icon(Icons.delete, color: Colors.red),
                                                                  onPressed: () => removeMuscleRecord(muscleKey, valueIndex),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        }).toList(),
                                                      );
                                                    },
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('Close'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        icon: const Icon(Icons.archive),
                                        label: const Text(
                                          'View Past Records',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ),
                                    ],
                                  ),
                                  );
                                }
                              );
                            },
                          label: const Text("Create/View Record", textAlign: TextAlign.center, style: TextStyle(fontSize: 22)),
                          icon: const Icon(Icons.add),
                          )
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildFitnessCard(
                        title: 'Weight', 
                        currentValue: muscleValues['Weight']?.last ?? 0.0,  
                        valueChange: muscleValues['Weight']!.length > 1 
                          ? calculateChange(muscleValues['Weight']!) 
                          : 0.0
                      ),
                      const SizedBox(width: 15),
                      buildFitnessCard(
                        title: 'Hip', 
                        currentValue: muscleValues['Hip']?.last ?? 0.0, 
                        valueChange: muscleValues['Hip']!.length > 1 
                          ? calculateChange(muscleValues['Hip']!) 
                          : 0.0
                      ),
                    ]
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildFitnessCard(
                        title: 'Neck', 
                        currentValue: muscleValues['Neck']?.last ?? 0.0, 
                        valueChange: muscleValues['Neck']!.length > 1 
                          ? calculateChange(muscleValues['Neck']!) 
                          : 0.0
                      ),
                      const SizedBox(width: 15),
                      buildFitnessCard(
                        title: 'Waist', 
                        currentValue: muscleValues['Waist']?.last ?? 0.0, 
                        valueChange: muscleValues['Waist']!.length > 1 
                          ? calculateChange(muscleValues['Waist']!) 
                          : 0.0
                      )
                    ]
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Your Body",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 132, 236, 188),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildFitnessCard(
                        title: 'Back', 
                        currentValue: muscleValues['Back']?.last ?? 0.0, 
                        valueChange: muscleValues['Back']!.length > 1 
                          ? calculateChange(muscleValues['Back']!) 
                          : 0.0
                      ),
                      const SizedBox(width: 15),
                      buildFitnessCard(
                        title: 'Chest', 
                        currentValue: muscleValues['Chest']?.last ?? 0.0, 
                        valueChange: muscleValues['Chest']!.length > 1 
                          ? calculateChange(muscleValues['Chest']!) 
                          : 0.0
                      )
                    ]
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildFitnessCard(
                        title: 'Right Bicep', 
                        currentValue: muscleValues['Right Bicep']?.last ?? 0.0, 
                        valueChange: muscleValues['Right Bicep']!.length > 1 
                          ? calculateChange(muscleValues['Right Bicep']!) 
                          : 0.0
                      ),
                      const SizedBox(width: 15),
                      buildFitnessCard(
                        title: 'Left Bicep', 
                        currentValue: muscleValues['Left Bicep']?.last ?? 0.0, 
                        valueChange: muscleValues['Left Bicep']!.length > 1 
                          ? calculateChange(muscleValues['Left Bicep']!) 
                          : 0.0
                      )
                    ]
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildFitnessCard(
                        title: 'Right Quad', 
                        currentValue: muscleValues['Right Quad']?.last ?? 0.0, 
                        valueChange: muscleValues['Right Quad']!.length > 1 
                          ? calculateChange(muscleValues['Right Quad']!) 
                          : 0.0
                      ),
                      const SizedBox(width: 15),
                      buildFitnessCard(
                        title: 'Left Quad', 
                        currentValue: muscleValues['Left Quad']?.last ?? 0.0, 
                        valueChange: muscleValues['Left Quad']!.length > 1 
                          ? calculateChange(muscleValues['Left Quad']!) 
                          : 0.0
                      )
                    ]
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildFitnessCard(
                        title: 'Right Calf', 
                        currentValue: muscleValues['Right Calf']?.last ?? 0.0, 
                        valueChange: muscleValues['Right Calf']!.length > 1 
                          ? calculateChange(muscleValues['Right Calf']!) 
                          : 0.0
                      ),
                      const SizedBox(width: 15),
                      buildFitnessCard(
                        title: 'Left Calf', 
                        currentValue: muscleValues['Left Calf']?.last ?? 0.0, 
                        valueChange: muscleValues['Left Calf']!.length > 1 
                          ? calculateChange(muscleValues['Left Calf']!) 
                          : 0.0
                      )
                    ]
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