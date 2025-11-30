import 'dart:io'; // File handle korar jonno
import 'package:flutter/foundation.dart'; // Platform check korar jonno
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Database
import 'dart:convert'; // Data convert
import 'package:file_picker/file_picker.dart'; // File bachar jonno
import 'package:path_provider/path_provider.dart'; // Folder khujar jonno
import 'package:open_filex/open_filex.dart'; // File open korar jonno
import 'package:path/path.dart' as path; // File name ber korar jonno
import 'package:webview_flutter/webview_flutter.dart'; // ERP Website

void main() {
  runApp(const DiaryApp());
}

class DiaryApp extends StatelessWidget {
  const DiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Diary',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00E5FF), // Neon Cyan
          brightness: Brightness.dark,
          primary: const Color(0xFF00E5FF),
          secondary: const Color(0xFFE040FB), // Neon Purple
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F0F), // Deep Dark Background
        cardColor: const Color(0xFF1A1A1A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

// --- SCREEN MANAGER (CUSTOM FLOATING MENU) ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    const TodoPage(),
    const MoneyManagerPage(), 
    const DocumentPage(),
    const ERPPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(20),
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withOpacity(0.95),
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, Icons.check_circle_outline, Icons.check_circle, 'Tasks', const Color(0xFF00E5FF)),
            _buildNavItem(1, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Wallet', const Color(0xFFE040FB)),
            _buildNavItem(2, Icons.folder_open, Icons.folder, 'Vault', const Color(0xFFFF6D00)),
            _buildNavItem(3, Icons.language, Icons.language, 'Portal', const Color(0xFF00E676)),
          ],
        ),
      ),
      extendBody: true,
    );
  }

  Widget _buildNavItem(int index, IconData iconOutlined, IconData iconFilled, String label, Color color) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected 
            ? BoxDecoration(
                color: color.withOpacity(0.2), 
                borderRadius: BorderRadius.circular(20)
              ) 
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? iconFilled : iconOutlined,
              color: isSelected ? color : Colors.grey,
              size: 26,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 1. TODO PAGE
// ==========================================
class TodoItem {
  String id;
  String title;
  bool isCompleted;

  TodoItem({required this.id, required this.title, this.isCompleted = false});

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'isCompleted': isCompleted};
  factory TodoItem.fromMap(Map<String, dynamic> map) => TodoItem(
    id: map['id'], 
    title: map['title'], 
    isCompleted: map['isCompleted']
  );
}

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  List<TodoItem> _todos = [];
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(_todos.map((e) => e.toMap()).toList());
    await prefs.setString('todo_list', encodedData);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('todo_list');
    if (savedData != null) {
      final List<dynamic> decodedData = jsonDecode(savedData);
      setState(() {
        _todos = decodedData.map((e) => TodoItem.fromMap(e)).toList();
      });
    }
  }

  void _addTodo() {
    if (_textController.text.trim().isEmpty) return;
    setState(() {
      _todos.add(TodoItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _textController.text.trim(),
      ));
      _textController.clear();
    });
    _saveData();
    Navigator.of(context).pop();
  }

  void _toggleTodo(int index) {
    setState(() { _todos[index].isCompleted = !_todos[index].isCompleted; });
    _saveData();
  }

  void _deleteTodo(int index) {
    setState(() { _todos.removeAt(index); });
    _saveData();
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(25, 25, 25, MediaQuery.of(context).viewInsets.bottom + 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Add New Task', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            TextField(
              controller: _textController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'What needs to be done?',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _addTodo(),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: _addTodo, 
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
              ),
              child: const Text('Create Task', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: _todos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rocket_launch_outlined, size: 80, color: Colors.grey.shade800),
                  const SizedBox(height: 20),
                  Text('No tasks yet. Stay productive!', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 150), 
              itemCount: _todos.length,
              itemBuilder: (context, index) {
                final todo = _todos[index];
                return Dismissible(
                  key: Key(todo.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _deleteTodo(index),
                  background: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.redAccent),
                  ),
                  child: Card(
                    color: const Color(0xFF1A1A1A),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: Colors.grey.shade900),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      leading: Checkbox(
                        value: todo.isCompleted, 
                        onChanged: (_) => _toggleTodo(index),
                        activeColor: const Color(0xFF00E5FF),
                        checkColor: Colors.black,
                        shape: const CircleBorder(),
                      ),
                      title: Text(todo.title, style: TextStyle(
                        decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                        color: todo.isCompleted ? Colors.grey : Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      )),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton(
          onPressed: _showAddDialog,
          backgroundColor: const Color(0xFF00E5FF),
          child: const Icon(Icons.add, color: Colors.black),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// ==========================================
// 2. MONEY MANAGER PAGE (UPDATED WITH REMAINING)
// ==========================================
class BudgetCategory {
  String id;
  String name;
  double totalAmount;
  double spentAmount;

  BudgetCategory({
    required this.id,
    required this.name,
    required this.totalAmount,
    this.spentAmount = 0.0,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'totalAmount': totalAmount, 'spentAmount': spentAmount
  };
  
  factory BudgetCategory.fromMap(Map<String, dynamic> map) => BudgetCategory(
    id: map['id'],
    name: map['name'],
    totalAmount: map['totalAmount'],
    spentAmount: map['spentAmount'],
  );

  double get remaining => totalAmount - spentAmount;
  double get progress => totalAmount == 0 ? 0 : (remaining / totalAmount);
}

class MoneyManagerPage extends StatefulWidget {
  const MoneyManagerPage({super.key});

  @override
  State<MoneyManagerPage> createState() => _MoneyManagerPageState();
}

class _MoneyManagerPageState extends State<MoneyManagerPage> {
  List<BudgetCategory> _budgets = [];
  double _monthlyLimit = 0.0;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  final List<String> _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(_budgets.map((e) => e.toMap()).toList());
    await prefs.setString('budget_list', encodedData);
    await prefs.setDouble('monthly_limit', _monthlyLimit);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('budget_list');
    if (savedData != null) {
      final List<dynamic> decodedData = jsonDecode(savedData);
      setState(() {
        _budgets = decodedData.map((e) => BudgetCategory.fromMap(e)).toList();
      });
    }
    setState(() {
      _monthlyLimit = prefs.getDouble('monthly_limit') ?? 0.0;
    });
  }

  double get _totalSpent => _budgets.fold(0, (sum, item) => sum + item.spentAmount);
  
  // ✅ NEW: Calculate Total Remaining
  double get _totalRemaining => _monthlyLimit - _totalSpent;
  
  String get _currentMonth {
    final now = DateTime.now();
    return _months[now.month - 1];
  }
  
  int get _daysRemaining {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    return lastDay - now.day;
  }

  void _setMonthlyLimit() {
    _amountController.text = _monthlyLimit == 0 ? '' : _monthlyLimit.toStringAsFixed(0);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Set Monthly Budget', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Total limit', prefixText: '৳ ', 
            filled: true, fillColor: const Color(0xFF2C2C2C),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE040FB), foregroundColor: Colors.white),
            onPressed: () {
              double? amount = double.tryParse(_amountController.text);
              if (amount != null) {
                setState(() => _monthlyLimit = amount);
                _saveData();
                Navigator.pop(context);
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  void _addBudget() {
    if (_nameController.text.isEmpty || _amountController.text.isEmpty) return;
    double? amount = double.tryParse(_amountController.text);
    if (amount == null) return;

    setState(() {
      _budgets.add(BudgetCategory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        totalAmount: amount,
      ));
    });
    _nameController.clear();
    _amountController.clear();
    _saveData();
    Navigator.of(context).pop();
  }

  void _addExpense(int index, double expense) {
    setState(() {
      _budgets[index].spentAmount += expense;
    });
    _saveData();
  }

  void _deleteBudget(int index) {
    setState(() { _budgets.removeAt(index); });
    _saveData();
  }

  void _showAddBudgetDialog() {
    _nameController.clear();
    _amountController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(25, 25, 25, MediaQuery.of(context).viewInsets.bottom + 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('New Category', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Name (e.g. Food)', filled: true, fillColor: Color(0xFF2C2C2C), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Budget (e.g. 500)', filled: true, fillColor: Color(0xFF2C2C2C), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: _addBudget,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE040FB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
              ),
              child: const Text('Create Category', style: TextStyle(fontWeight: FontWeight.bold))
            ),
          ],
        ),
      ),
    );
  }

  void _showExpenseDialog(int index) {
    _amountController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Add Expense', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            hintText: 'Amount', prefixText: '৳ ', 
            filled: true, fillColor: const Color(0xFF2C2C2C),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              double? amount = double.tryParse(_amountController.text);
              if (amount != null) {
                _addExpense(index, amount);
                Navigator.pop(context);
              }
            },
            child: const Text('Spend'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double globalProgress = _monthlyLimit == 0 ? 0 : (_totalSpent / _monthlyLimit);
    if (globalProgress > 1) globalProgress = 1;
    
    // Low balance alert (Red if < 20% remaining)
    bool isLowBalance = globalProgress > 0.8;

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: Column(
        children: [
          // --- UPDATED DASHBOARD CARD ---
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)], 
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: const Color(0xFF4A148C).withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Column(
              children: [
                // Top Row: Month & Days
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$_currentMonth ${DateTime.now().year}', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
                      child: Text('$_daysRemaining Days Left', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Middle Row: TOTAL REMAINING (Big & Center)
                const Text('Remaining Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 5),
                Text(
                  '৳${_totalRemaining.toStringAsFixed(0)}', 
                  style: TextStyle(
                    fontSize: 40, 
                    fontWeight: FontWeight.bold, 
                    color: isLowBalance ? const Color(0xFFFF1744) : Colors.white, // Red if low
                    shadows: [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)]
                  )
                ),

                const SizedBox(height: 25),
                
                // Bottom Row: Spent & Limit
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Spent', style: TextStyle(color: Colors.white60, fontSize: 12)),
                        Text('৳${_totalSpent.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: _setMonthlyLimit,
                          child: Row(
                            children: const [
                              Text('Limit ', style: TextStyle(color: Colors.white60, fontSize: 12)),
                              Icon(Icons.edit, size: 12, color: Colors.white60),
                            ],
                          ),
                        ),
                        Text('৳${_monthlyLimit.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: globalProgress,
                    minHeight: 8,
                    backgroundColor: Colors.black.withOpacity(0.2),
                    color: isLowBalance ? const Color(0xFFFF1744) : const Color(0xFF00E5FF),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _budgets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet, size: 60, color: Colors.grey.shade800),
                        const SizedBox(height: 15),
                        Text('Set your budget to start tracking', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 150),
                    itemCount: _budgets.length,
                    itemBuilder: (context, index) {
                      final budget = _budgets[index];
                      final double progress = budget.progress;
                      
                      return Card(
                        color: const Color(0xFF1A1A1A),
                        margin: const EdgeInsets.only(bottom: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(budget.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                    onPressed: () => _deleteBudget(index),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Spent: ৳${budget.spentAmount.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey.shade400)),
                                  Text('Limit: ৳${budget.totalAmount.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey.shade400)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: progress < 0 ? 0 : progress,
                                backgroundColor: Colors.grey.shade900,
                                color: progress > 0.8 ? const Color(0xFFFF1744) : const Color(0xFFE040FB),
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              const SizedBox(height: 15),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _showExpenseDialog(index),
                                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFFF1744),
                                    side: const BorderSide(color: Color(0xFFFF1744)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                                  ),
                                  label: const Text('Spend Money'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0), 
        child: FloatingActionButton.extended(
          onPressed: _showAddBudgetDialog,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFFE040FB),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// ==========================================
// 3. DOCUMENT PAGE (Fixed Button & Color)
// ==========================================
class DocumentPage extends StatefulWidget {
  const DocumentPage({super.key});

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  List<String> _filePaths = [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _filePaths = prefs.getStringList('saved_docs') ?? [];
    });
  }

  Future<void> _pickAndSaveFile() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feature only available on Mobile')),
      );
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        File file = File(result.files.single.path!);
        final appDir = await getApplicationDocumentsDirectory();
        final String fileName = path.basename(file.path);
        final File savedFile = await file.copy('${appDir.path}/$fileName');

        final prefs = await SharedPreferences.getInstance();
        List<String> currentList = prefs.getStringList('saved_docs') ?? [];
        currentList.add(savedFile.path);
        await prefs.setStringList('saved_docs', currentList);

        _loadDocuments();
      }
    } catch (e) {
      // Error handle
    }
  }

  void _openFile(String filePath) async {
    if (!kIsWeb) {
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('খুলতে পারছি না: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteFile(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> currentList = prefs.getStringList('saved_docs') ?? [];
    currentList.removeAt(index);
    await prefs.setStringList('saved_docs', currentList);
    _loadDocuments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vault')),
      body: _filePaths.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_copy_outlined, size: 80, color: Colors.grey.shade800),
                  const SizedBox(height: 15),
                  Text('Upload notes, receipts, or images', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
              itemCount: _filePaths.length,
              itemBuilder: (context, index) {
                final String filePath = _filePaths[index];
                final String fileName = path.basename(filePath);
                final bool isPdf = fileName.toLowerCase().endsWith('.pdf');

                return Card(
                  color: const Color(0xFF1A1A1A),
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isPdf ? Colors.redAccent.withOpacity(0.1) : Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)
                      ),
                      child: Icon(
                        isPdf ? Icons.picture_as_pdf : Icons.image,
                        color: isPdf ? Colors.redAccent : Colors.blueAccent,
                        size: 24,
                      ),
                    ),
                    title: Text(fileName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                    subtitle: Text('Tap to open', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    onTap: () => _openFile(filePath),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey),
                      onPressed: () => _deleteFile(index),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0), 
        child: FloatingActionButton.extended(
          onPressed: _pickAndSaveFile,
          icon: const Icon(Icons.upload_file, color: Colors.black),
          label: const Text('Upload', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFFFF6D00),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// ==========================================
// 4. ERP PAGE
// ==========================================
class ERPPage extends StatefulWidget {
  const ERPPage({super.key});

  @override
  State<ERPPage> createState() => _ERPPageState();
}

class _ERPPageState extends State<ERPPage> {
  WebViewController? _controller; 
  bool _isLoading = true;
  bool _isMobile = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _isMobile = true;
      const String erpUrl = 'https://erp.uttara.ac.bd/'; 

      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) setState(() => _isLoading = true);
            },
            onPageFinished: (String url) {
              if (mounted) setState(() => _isLoading = false);
            },
          ),
        )
        ..loadRequest(Uri.parse(erpUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isMobile) {
      return Scaffold(
        appBar: AppBar(title: const Text('Portal')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.desktop_mac_outlined, size: 80, color: Colors.grey.shade800),
              const SizedBox(height: 20),
              const Text(
                'Please run on a Mobile Device',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller?.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_controller != null) WebViewWidget(controller: _controller!),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
        ],
      ),
    );
  }
}