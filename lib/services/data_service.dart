import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/task.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class DataService {
  static const String _usersKey = 'users';
  static const String _tasksKey = 'tasks';
  static const String _settingsKey = 'settings';
  static const String _redemptionsKey = 'redemptions';
  static const String _lastResetDateKey =
      'lastResetDate'; // New key for tracking resets
  static const String _lastWeeklyResetDateKey =
      'lastWeeklyResetDate'; // For weekly resets
  static const int _maxRetries = 3; // Retry failed writes
  static const Duration _retryDelay = Duration(milliseconds: 100);

  Future<List<User>> fetchUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) {
      debugPrint('DataService: No users found in SharedPreferences');
      return [];
    }
    try {
      final List<dynamic> usersList = jsonDecode(usersJson);
      final users = usersList.map((json) => User.fromJson(json)).toList();
      debugPrint('DataService: Fetched ${users.length} users');
      return users;
    } catch (e) {
      debugPrint('DataService: Error decoding users JSON: $e');
      return [];
    }
  }

  Future<bool> saveUsers(List<User> users) async {
    return _saveWithRetry(_usersKey,
        jsonEncode(users.map((user) => user.toJson()).toList()), 'users');
  }

  Future<List<Task>> fetchTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString(_tasksKey);
    if (tasksJson == null) {
      debugPrint('DataService: No tasks found in SharedPreferences');
      return [];
    }
    try {
      final List<dynamic> tasksList = jsonDecode(tasksJson);
      final tasks = tasksList.map((json) => Task.fromJson(json)).toList();
      debugPrint(
          'DataService: Fetched ${tasks.length} tasks: ${tasks.map((t) => t.id).toList()}');
      return tasks;
    } catch (e) {
      debugPrint('DataService: Error decoding tasks JSON: $e');
      return [];
    }
  }

  Future<bool> addTask(Task task) async {
    final tasks = await fetchTasks();
    final existingIndex = tasks.indexWhere((t) => t.id == task.id);
    if (existingIndex != -1) {
      tasks[existingIndex] = task;
    } else {
      tasks.add(task);
    }
    final success = await _saveWithRetry(_tasksKey,
        jsonEncode(tasks.map((t) => t.toJson()).toList()), 'task ${task.id}');
    debugPrint(
        'DataService: ${success ? 'Saved' : 'Failed to save'} task: ${task.id} - ${task.title}');
    return success;
  }

  Future<bool> updateTask(Task task) async {
    return addTask(task);
  }

  Future<Map<String, dynamic>> fetchSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);
    if (settingsJson == null) {
      debugPrint('DataService: No settings found in SharedPreferences');
      return {};
    }
    try {
      final settings = jsonDecode(settingsJson) as Map<String, dynamic>;
      debugPrint('DataService: Fetched settings: $settings');
      return settings;
    } catch (e) {
      debugPrint('DataService: Error decoding settings JSON: $e');
      return {};
    }
  }

  Future<bool> saveSettings(Map<String, dynamic> settings) async {
    final success =
        await _saveWithRetry(_settingsKey, jsonEncode(settings), 'settings');
    debugPrint(
        'DataService: ${success ? 'Saved' : 'Failed to save'} settings: $settings');
    return success;
  }

  Future<List<Map<String, dynamic>>> fetchRedemptionRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final redemptionsJson = prefs.getString(_redemptionsKey);
    if (redemptionsJson == null) {
      debugPrint(
          'DataService: No redemption requests found in SharedPreferences');
      return [];
    }
    try {
      final List<dynamic> redemptionsList = jsonDecode(redemptionsJson);
      final redemptions = redemptionsList.cast<Map<String, dynamic>>();
      debugPrint(
          'DataService: Fetched ${redemptions.length} redemption requests');
      return redemptions;
    } catch (e) {
      debugPrint('DataService: Error decoding redemptions JSON: $e');
      return [];
    }
  }

  Future<bool> saveRedemptionRequests(
      List<Map<String, dynamic>> requests) async {
    final success = await _saveWithRetry(
        _redemptionsKey, jsonEncode(requests), 'redemption requests');
    debugPrint(
        'DataService: ${success ? 'Saved' : 'Failed to save'} redemption requests: $requests');
    return success;
  }

  Future<bool> deleteKidData(String kidId) async {
    try {
      // Fetch current data
      final users = await fetchUsers();
      final tasks = await fetchTasks();
      final settings = await fetchSettings();
      final redemptions = await fetchRedemptionRequests();

      // Update data
      final updatedUsers = users.where((u) => u.id != kidId).toList();
      final updatedTasks =
          tasks.where((t) => !t.id.startsWith('${kidId}_')).toList();
      final updatedSettings = Map<String, dynamic>.from(settings)
        ..removeWhere((key, _) => key.startsWith('${kidId}_'));
      final updatedRedemptions =
          redemptions.where((r) => r['kidId'] != kidId).toList();

      // Save updated data with retries
      final usersSuccess = await saveUsers(updatedUsers);
      final tasksSuccess = await _saveWithRetry(
          _tasksKey,
          jsonEncode(updatedTasks.map((t) => t.toJson()).toList()),
          'tasks after deletion');
      final settingsSuccess = await saveSettings(updatedSettings);
      final redemptionsSuccess =
          await saveRedemptionRequests(updatedRedemptions);

      final success =
          usersSuccess && tasksSuccess && settingsSuccess && redemptionsSuccess;
      debugPrint(
          'DataService: ${success ? 'Successfully' : 'Failed to'} delete data for kid: $kidId');
      return success;
    } catch (e) {
      debugPrint('DataService: Error deleting kid data: $e');
      return false;
    }
  }

  // New method to get the last reset date for a specific kid
  Future<DateTime?> getLastResetDate(String kidId) async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString('${_lastResetDateKey}_$kidId');
    if (dateStr == null) {
      debugPrint('DataService: No last reset date found for kid: $kidId');
      return null;
    }
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      debugPrint('DataService: Error parsing last reset date: $e');
      return null;
    }
  }

  // New method to save the last reset date for a specific kid
  Future<bool> saveLastResetDate(String kidId, DateTime date) async {
    final success = await _saveWithRetry(
      '${_lastResetDateKey}_$kidId',
      date.toIso8601String(),
      'last reset date for $kidId',
    );
    debugPrint(
        'DataService: ${success ? 'Saved' : 'Failed to save'} last reset date for kid: $kidId');
    return success;
  }

  // New method to get the last weekly reset date for a specific kid
  Future<DateTime?> getLastWeeklyResetDate(String kidId) async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString('${_lastWeeklyResetDateKey}_$kidId');
    if (dateStr == null) {
      debugPrint(
          'DataService: No last weekly reset date found for kid: $kidId');
      return null;
    }
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      debugPrint('DataService: Error parsing last weekly reset date: $e');
      return null;
    }
  }

  // New method to save the last weekly reset date for a specific kid
  Future<bool> saveLastWeeklyResetDate(String kidId, DateTime date) async {
    final success = await _saveWithRetry(
      '${_lastWeeklyResetDateKey}_$kidId',
      date.toIso8601String(),
      'last weekly reset date for $kidId',
    );
    debugPrint(
        'DataService: ${success ? 'Saved' : 'Failed to save'} last weekly reset date for kid: $kidId');
    return success;
  }

  // New method to get tasks completed today for a specific kid and category
  Future<List<Task>> getTasksCompletedToday(
      String kidId, String category) async {
    final tasks = await fetchTasks();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return tasks
        .where((task) =>
            task.id.startsWith('${kidId}_') &&
            task.category == category &&
            task.isCompleted &&
            task.completedAt != null &&
            task.completedAt!
                .isAfter(today.subtract(const Duration(seconds: 1))))
        .toList();
  }

  // New method to reset daily task completion status
  Future<bool> resetDailyTaskCompletion(String kidId) async {
    debugPrint('DataService: Resetting daily task completion for kid: $kidId');
    try {
      // We're not actually resetting the task completion status
      // This is just tracking that we've done the reset
      return await saveLastResetDate(kidId, DateTime.now());
    } catch (e) {
      debugPrint('DataService: Error resetting daily task completion: $e');
      return false;
    }
  }

  Future<bool> _saveWithRetry(String key, String value, String dataType) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final success = await prefs.setString(key, value);
        if (success) {
          return true;
        }
        debugPrint(
            'DataService: Attempt $attempt failed to save $dataType to SharedPreferences');
      } catch (e) {
        debugPrint(
            'DataService: Error on attempt $attempt saving $dataType: $e');
      }
      if (attempt < _maxRetries) {
        await Future.delayed(_retryDelay);
      }
    }
    debugPrint(
        'DataService: Failed to save $dataType after $_maxRetries attempts');
    return false;
  }

  Future<Map<String, dynamic>> fetchProgress(String userId) async {
    // Assuming you're using SharedPreferences or similar
    final prefs = await SharedPreferences.getInstance();
    return {
      '${userId}_choreDailyAchieved':
          prefs.getInt('${userId}_choreDailyAchieved') ?? 0,
      '${userId}_choreWeeklyAchieved':
          prefs.getInt('${userId}_choreWeeklyAchieved') ?? 0,
      '${userId}_prayerDailyAchieved':
          prefs.getInt('${userId}_prayerDailyAchieved') ?? 0,
      '${userId}_prayerWeeklyAchieved':
          prefs.getInt('${userId}_prayerWeeklyAchieved') ?? 0,
      '${userId}_studyDailyAchieved':
          prefs.getInt('${userId}_studyDailyAchieved') ?? 0,
      '${userId}_studyWeeklyAchieved':
          prefs.getInt('${userId}_studyWeeklyAchieved') ?? 0,
    };
  }

  Future<void> saveProgress(
      String userId, Map<String, dynamic> progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${userId}_choreDailyAchieved',
        progress['${userId}_choreDailyAchieved']);
    await prefs.setInt('${userId}_choreWeeklyAchieved',
        progress['${userId}_choreWeeklyAchieved']);
    await prefs.setInt('${userId}_prayerDailyAchieved',
        progress['${userId}_prayerDailyAchieved']);
    await prefs.setInt('${userId}_prayerWeeklyAchieved',
        progress['${userId}_prayerWeeklyAchieved']);
    await prefs.setInt('${userId}_studyDailyAchieved',
        progress['${userId}_studyDailyAchieved']);
    await prefs.setInt('${userId}_studyWeeklyAchieved',
        progress['${userId}_studyWeeklyAchieved']);
  }
}
