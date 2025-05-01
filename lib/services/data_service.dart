import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/task.dart';

class DataService {
  static const String _usersKey = 'users';
  static const String _tasksKey = 'tasks';
  static const String _settingsKey = 'settings';
  static const String _redemptionsKey = 'redemptions';

  Future<List<User>> fetchUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) return [];
    final List<dynamic> usersList = jsonDecode(usersJson);
    return usersList.map((json) => User.fromJson(json)).toList();
  }

  Future<void> saveUsers(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = jsonEncode(users.map((user) => user.toJson()).toList());
    await prefs.setString(_usersKey, usersJson);
  }

  Future<List<Task>> fetchTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString(_tasksKey);
    if (tasksJson == null) return [];
    final List<dynamic> tasksList = jsonDecode(tasksJson);
    final tasks = tasksList.map((json) => Task.fromJson(json)).toList();
    print('Fetched tasks: ${tasks.map((t) => t.id).toList()}'); // Debug
    return tasks;
  }

  Future<void> addTask(Task task) async {
    final tasks = await fetchTasks();
    final existingIndex = tasks.indexWhere((t) => t.id == task.id);
    if (existingIndex != -1) {
      tasks[existingIndex] = task;
    } else {
      tasks.add(task);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _tasksKey,
      jsonEncode(tasks.map((t) => t.toJson()).toList()),
    );
    print('Saved task: ${task.id} - ${task.title}'); // Debug
  }

  Future<void> updateTask(Task task) async {
    await addTask(task);
  }

  Future<Map<String, dynamic>> fetchSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);
    if (settingsJson == null) return {};
    return jsonDecode(settingsJson);
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings));
    print('Saved settings: $settings'); // Debug
  }

  Future<List<Map<String, dynamic>>> fetchRedemptionRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final redemptionsJson = prefs.getString(_redemptionsKey);
    if (redemptionsJson == null) return [];
    final List<dynamic> redemptionsList = jsonDecode(redemptionsJson);
    return redemptionsList.cast<Map<String, dynamic>>();
  }

  Future<void> saveRedemptionRequests(
    List<Map<String, dynamic>> requests,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_redemptionsKey, jsonEncode(requests));
    print('Saved redemptions: $requests'); // Debug
  }

  Future<void> deleteKidData(String kidId) async {
    final prefs = await SharedPreferences.getInstance();
    // Remove user
    final users = await fetchUsers();
    final updatedUsers = users.where((u) => u.id != kidId).toList();
    await saveUsers(updatedUsers);
    // Remove tasks
    final tasks = await fetchTasks();
    final updatedTasks =
        tasks.where((t) => !t.id.startsWith('${kidId}_')).toList();
    await prefs.setString(
      _tasksKey,
      jsonEncode(updatedTasks.map((t) => t.toJson()).toList()),
    );
    // Remove settings
    final settings = await fetchSettings();
    final updatedSettings = Map<String, dynamic>.from(settings)
      ..removeWhere((key, _) => key.startsWith('${kidId}_'));
    await saveSettings(updatedSettings);
    // Remove redemption requests
    final redemptions = await fetchRedemptionRequests();
    final updatedRedemptions =
        redemptions.where((r) => r['kidId'] != kidId).toList();
    await saveRedemptionRequests(updatedRedemptions);
    print('Deleted data for kid: $kidId'); // Debug
  }
}
