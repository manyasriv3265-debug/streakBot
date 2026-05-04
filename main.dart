import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(StreakBotApp());
}

class StreakBotApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StreakBot',
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  int streak = 0;
  String lastDate = "";

  List<Map<String, dynamic>> tasks = [];

  String selectedCategory = "All";

  TextEditingController taskController = TextEditingController();

  List<String> categories = ["All", "DSA", "Study", "Fitness"];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // 🔹 Load Data
  void loadData() async {
    final prefs = await SharedPreferences.getInstance();

    String today = DateTime.now().toString().substring(0, 10);

    String? taskData = prefs.getString('tasks');

    if (taskData != null) {
      tasks = List<Map<String, dynamic>>.from(jsonDecode(taskData));
    } else {
      tasks = [
        {"title": "Solve Two Sum", "completed": false, "category": "DSA"},
        {"title": "Workout 20 mins", "completed": false, "category": "Fitness"},
      ];
    }

    setState(() {
      streak = prefs.getInt('streak') ?? 0;
      lastDate = prefs.getString('lastDate') ?? "";
    });

    if (lastDate != "" && lastDate != today) {
      DateTime last = DateTime.parse(lastDate);
      DateTime now = DateTime.now();

      if (now.difference(last).inDays > 1) {
        setState(() {
          streak = 0;
        });
      }
    }
  }

  // 🔹 Save Tasks
  void saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('tasks', jsonEncode(tasks));
  }

  // 🔹 Increase Streak
  void increaseStreak() async {
    final prefs = await SharedPreferences.getInstance();

    String today = DateTime.now().toString().substring(0, 10);

    if (lastDate == today) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Already completed today!")),
      );
      return;
    }

    setState(() {
      streak++;
      lastDate = today;
    });

    prefs.setInt('streak', streak);
    prefs.setString('lastDate', lastDate);
  }

  // 🔹 Add Task
  void addTask(String category) {
    if (taskController.text.trim().isEmpty) return;

    setState(() {
      tasks.add({
        "title": taskController.text,
        "completed": false,
        "category": category,
      });
      taskController.clear();
    });

    saveTasks();
  }

  // 🔹 Toggle Task
  void toggleTask(int index) {
    setState(() {
      tasks[index]["completed"] = !tasks[index]["completed"];
    });

    saveTasks();
  }

  // 🔹 Delete Task
  void deleteTask(int index) {
    setState(() {
      tasks.removeAt(index);
    });

    saveTasks();
  }

  // 🔹 Filter tasks
  List<Map<String, dynamic>> getFilteredTasks() {
    if (selectedCategory == "All") return tasks;

    return tasks.where((task) => task["category"] == selectedCategory).toList();
  }

  // 🔹 Progress
  double getProgress() {
    if (tasks.isEmpty) return 0;

    int done = tasks.where((t) => t["completed"]).length;
    return done / tasks.length;
  }

  @override
  Widget build(BuildContext context) {

    double progress = getProgress();
    List<Map<String, dynamic>> filtered = getFilteredTasks();

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: Text("StreakBot"),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            Text("🔥 $streak Day Streak",
                style: TextStyle(color: Colors.green, fontSize: 24)),

            SizedBox(height: 10),

            ElevatedButton(
              onPressed: increaseStreak,
              child: Text("Start Today"),
            ),

            SizedBox(height: 20),

            // 🔹 Add Task
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: taskController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Enter task",
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                DropdownButton<String>(
                  dropdownColor: Colors.black,
                  value: "DSA",
                  items: ["DSA", "Study", "Fitness"]
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e, style: TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    addTask(value!);
                  },
                )
              ],
            ),

            SizedBox(height: 20),

            // 🔹 Categories Filter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: categories.map((cat) {
                return ChoiceChip(
                  label: Text(cat),
                  selected: selectedCategory == cat,
                  onSelected: (_) {
                    setState(() {
                      selectedCategory = cat;
                    });
                  },
                );
              }).toList(),
            ),

            SizedBox(height: 20),

            LinearProgressIndicator(value: progress),

            SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {

                  final task = filtered[index];
                  final realIndex = tasks.indexOf(task);

                  return Dismissible(
                    key: Key(task["title"]),
                    onDismissed: (_) => deleteTask(realIndex),

                    child: ListTile(
                      title: Text(
                        task["title"],
                        style: TextStyle(
                          color: Colors.white,
                          decoration: task["completed"]
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: Text(task["category"],
                          style: TextStyle(color: Colors.grey)),
                      trailing: Checkbox(
                        value: task["completed"],
                        onChanged: (_) => toggleTask(realIndex),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}