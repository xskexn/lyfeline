import 'package:flutter/material.dart';
import 'package:lyfeline/data/financialStorage.dart';
import 'package:intl/intl.dart';

class FinancialAspectPage extends StatefulWidget {
  const FinancialAspectPage({Key? key}) : super(key: key);

  @override
  FinancialAspectPageState createState() => FinancialAspectPageState();
}

class FinancialAspectPageState extends State<FinancialAspectPage> {
  late SharedFinancialStorage storage;
  bool isLoading = true;
  
  Map<String, List<double>> financialValues = {};
  int currentLevel = 1;
  double totalAmount = 0.0;
  DateTime? lastReset;

  @override
  void initState() {
    super.initState();
    initStorage();
  }

  Future<void> initStorage() async {
    storage = await SharedFinancialStorage.init("financial");
    
    final Map<String, List<double>> defaultFinancialValues = {
      'Easy-Access Savings': [0],
      'Investments': [0],
      'Long-Term Savings': [0],
      'Emergency Fund': [0]
    };
    
    final (loadedValues, loadedLastReset, loadedLevel, loadedTotal) = 
        await storage.loadData(defaultFinancialValues);
    
    setState(() {
      financialValues = loadedValues;
      lastReset = loadedLastReset;
      currentLevel = loadedLevel;
      totalAmount = loadedTotal;
      isLoading = false;
    });
  }

  Future<void> addFinancialValue(String accountType, double amount) async {
    setState(() {
      if (financialValues.containsKey(accountType)) {
        final currentTotal = financialValues[accountType]!.last;
        financialValues[accountType]!.add(currentTotal + amount);
      } else {
        financialValues[accountType] = [amount];
      }
    });
    
    await storage.saveData(financialValues);
    await initStorage();
  }

  Future<void> updateFinancialValue(String accountType, int index, double newValue) async {
    setState(() {
      if (financialValues.containsKey(accountType) && index < financialValues[accountType]!.length) {
        financialValues[accountType]![index] = newValue;
      }
    });
    
    await storage.saveData(financialValues);
    await initStorage();
  }

  Future<void> deleteFinancialValue(String accountType, int index) async {
    setState(() {
      if (financialValues.containsKey(accountType) && index < financialValues[accountType]!.length) {
        financialValues[accountType]!.removeAt(index);
        if (financialValues[accountType]!.isEmpty) {
          financialValues[accountType]!.add(0.0);
        }
      }
    });
    
    await storage.saveData(financialValues);
    await initStorage();
  }

  Future<void> addFinancialValueDialog({required String accountType}) async {
    final controller = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add to $accountType"),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount to add (£)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text) ?? 0.0;
              if (value > 0) {
                addFinancialValue(accountType, value);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void viewPastRecords(String accountType) {
    final records = financialValues[accountType] ?? [];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$accountType History"),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final isLatest = index == records.length - 1;
              return ListTile(
                title: Text("${DateFormat('MMM dd, yyyy').format(DateTime.now().subtract(Duration(days: (records.length - index - 1) * 7)))}"),
                subtitle: Text("£${records[index].toStringAsFixed(2)}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLatest) const Icon(Icons.star, color: Colors.amber),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                      onPressed: () => editRecord(accountType, index, records[index]),
                    ),
                    if (!isLatest) IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () => deleteFinancialValue(accountType, index),
                    ),
                  ],
                ),
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
      ),
    );
  }

  Future<void> editRecord(String accountType, int index, double currentValue) async {
    final controller = TextEditingController(text: currentValue.toString());
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit $accountType Record"),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount (£)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text) ?? 0.0;
              updateFinancialValue(accountType, index, value);
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget buildAccountCard(String account, double currentValue, int recordCount, Color color) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: () => viewPastRecords(account),
        onLongPress: () => addFinancialValueDialog(accountType: account),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      account,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "£${currentValue.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "$recordCount records",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLevelCard() {
    final progress = storage.getLevelProgress(totalAmount, currentLevel);
    final nextLevelAmount = storage.getRequiredAmountForNextLevel(currentLevel, totalAmount);
    
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
                      "Level $currentLevel",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "£${totalAmount.toStringAsFixed(2)}",
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
              valueColor: const AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 115, 207, 131)),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              "£${nextLevelAmount.toStringAsFixed(2)} to level ${currentLevel + 1}",
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
  Widget buildAccountButton(String account, Color color) {
    return ActionChip(
      avatar: Icon(Icons.account_balance_wallet, size: 18, color: color),
      label: Text(account),
      onPressed: () {
        Navigator.pop(context);
        addFinancialValueDialog(accountType: account);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Financial Aspect"),
        actions: [
          IconButton(
            icon: const  Icon(Icons.refresh),
            onPressed: initStorage,
            tooltip: "Refresh Values",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildLevelCard(),
            const SizedBox(height: 16),            
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  buildAccountCard('Easy-Access Savings', financialValues['Easy-Access Savings']?.reduce((value, element) => value + element)?? 0.0, financialValues['Easy-Access Savings']?.length ?? 0, Colors.blue),
                  buildAccountCard('Investments', financialValues['Investments']?.reduce((value, element) => value + element) ?? 0.0, financialValues['Investments']?.length ?? 0, Colors.purple),
                  buildAccountCard('Long-Term Savings', financialValues['Long-Term Savings']?.reduce((value, element) => value + element) ?? 0.0, financialValues['Long-Term Savings']?.length ?? 0, Colors.green),
                  buildAccountCard('Emergency Fund', financialValues['Emergency Fund']?.reduce((value, element) => value + element) ?? 0.0, financialValues['Emergency Fund']?.length ?? 0, Colors.orange),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 250,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Container(
                        padding: const  EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Add to Account",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                buildAccountButton('Easy-Access Savings', Colors.blue),
                                buildAccountButton('Investments', Colors.purple),
                                buildAccountButton('Long-Term Savings', Colors.green),
                                buildAccountButton('Emergency Fund', Colors.orange),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const  Text('Add Funds'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}