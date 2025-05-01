import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/task.dart';
import '../services/data_service.dart';
import '../widgets/task_tile.dart';
import '../widgets/congratulatory_widget.dart';
import '../utils/constants.dart';
import 'package:flutter/services.dart';

class KidDashboard extends StatefulWidget {
  final User user;

  const KidDashboard({super.key, required this.user});

  @override
  State<KidDashboard> createState() => _KidDashboardState();
}

class _KidDashboardState extends State<KidDashboard>
    with SingleTickerProviderStateMixin {
  final DataService _dataService = DataService();
  late TabController _tabController;
  List<Task> _chores = [];
  List<Task> _prayers = [];
  List<Task> _study = [];
  int _choreDailyAchieved = 0;
  int _choreWeeklyAchieved = 0;
  int _prayerDailyAchieved = 0;
  int _prayerWeeklyAchieved = 0;
  int _studyDailyAchieved = 0;
  int _studyWeeklyAchieved = 0;
  int _choreDailyTarget = 0;
  int _choreWeeklyTarget = 0;
  int _prayerDailyTarget = 0;
  int _prayerWeeklyTarget = 0;
  int _studyDailyTarget = 0;
  int _studyWeeklyTarget = 0;
  int _chorePoints = 2;
  int _prayerPoints = 1;
  int _studyPoints = 2;
  int _points = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData().then((_) {
      _checkAndResetDaily();
    });
  }

  Future<void> _loadData() async {
    final tasks = await _dataService.fetchTasks();
    final settings = await _dataService.fetchSettings();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _choreDailyAchieved = _chores
        .where((t) =>
            t.isCompleted &&
            t.completedAt != null &&
            t.completedAt!.isAfter(today))
        .length;

    _prayerDailyAchieved = _prayers
        .where((t) =>
            t.isCompleted &&
            t.completedAt != null &&
            t.completedAt!.isAfter(today))
        .length;

    _studyDailyAchieved = _study
        .where((t) =>
            t.isCompleted &&
            t.completedAt != null &&
            t.completedAt!.isAfter(today))
        .length;
    setState(() {
      _chores = tasks
          .where(
            (t) =>
                t.id.startsWith('${widget.user.id}_chore_') &&
                t.category == AppConstants.choreCategory,
          )
          .toList();
      _prayers = tasks
          .where(
            (t) =>
                t.id.startsWith('${widget.user.id}_prayer_') &&
                t.category == AppConstants.prayerCategory,
          )
          .toList();
      _study = tasks
          .where(
            (t) =>
                t.id.startsWith('${widget.user.id}_study_') &&
                t.category == AppConstants.studyCategory,
          )
          .toList();
      print(
        'Kid ${widget.user.name} - Chores: ${_chores.map((t) => t.title).toList()}',
      ); // Debug
      print(
        'Kid ${widget.user.name} - Prayers: ${_prayers.map((t) => t.title).toList()}',
      ); // Debug
      print(
        'Kid ${widget.user.name} - Study: ${_study.map((t) => t.title).toList()}',
      ); // Debug
      _choreDailyTarget = settings['${widget.user.id}_choreDailyTarget'] ?? 0;
      _choreWeeklyTarget = settings['${widget.user.id}_choreWeeklyTarget'] ?? 0;
      _prayerDailyTarget = settings['${widget.user.id}_prayerDailyTarget'] ?? 0;
      _prayerWeeklyTarget =
          settings['${widget.user.id}_prayerWeeklyTarget'] ?? 0;
      _studyDailyTarget = settings['${widget.user.id}_studyDailyTarget'] ?? 0;
      _studyWeeklyTarget = settings['${widget.user.id}_studyWeeklyTarget'] ?? 0;
      _chorePoints = settings['${widget.user.id}_chorePoints'] ?? 2;
      _prayerPoints = settings['${widget.user.id}_prayerPoints'] ?? 1;
      _studyPoints = settings['${widget.user.id}_studyPoints'] ?? 2;
      _points = settings['${widget.user.id}_points'] ?? 0;
      _choreDailyAchieved = _chores.where((t) => t.isCompleted).length;
      _choreWeeklyAchieved = _choreDailyAchieved;
      _prayerDailyAchieved = _prayers.where((t) => t.isCompleted).length;
      _prayerWeeklyAchieved = _prayerDailyAchieved;
      _studyDailyAchieved = _study.where((t) => t.isCompleted).length;
      _studyWeeklyAchieved = _studyDailyAchieved;
    });
  }

  void _toggleTaskCompletion(Task task, bool completed) {
    setState(() {
      final taskList = task.category == AppConstants.choreCategory
          ? _chores
          : task.category == AppConstants.prayerCategory
              ? _prayers
              : _study;
      final index = taskList.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        taskList[index] = Task(
          id: task.id,
          title: task.title,
          description: task.description,
          category: task.category,
          isCompleted: completed,
          iconName: task.iconName,
          completedAt: completed
              ? DateTime.now()
              : null, // Set timestamp when completing
        );
        final pointsChange = completed
            ? (task.category == AppConstants.choreCategory
                ? _chorePoints
                : task.category == AppConstants.prayerCategory
                    ? _prayerPoints
                    : _studyPoints)
            : -(task.category == AppConstants.choreCategory
                ? _chorePoints
                : task.category == AppConstants.prayerCategory
                    ? _prayerPoints
                    : _studyPoints);
        if (task.category == AppConstants.choreCategory) {
          _choreDailyAchieved += completed ? 1 : -1;
          _choreWeeklyAchieved += completed ? 1 : -1;
        } else if (task.category == AppConstants.prayerCategory) {
          _prayerDailyAchieved += completed ? 1 : -1;
          _prayerWeeklyAchieved += completed ? 1 : -1;
        } else if (task.category == AppConstants.studyCategory) {
          _studyDailyAchieved += completed ? 1 : -1;
          _studyWeeklyAchieved += completed ? 1 : -1;
        }
        _points += pointsChange;
        _points = _points.clamp(0, double.infinity).toInt();
        if (completed) {
          _showCongratulationDialog(task);
        }
        _dataService.updateTask(taskList[index]);
        _dataService.saveSettings({
          '${widget.user.id}_points': _points,
          '${widget.user.id}_choreDailyTarget': _choreDailyTarget,
          '${widget.user.id}_choreWeeklyTarget': _choreWeeklyTarget,
          '${widget.user.id}_prayerDailyTarget': _prayerDailyTarget,
          '${widget.user.id}_prayerWeeklyTarget': _prayerWeeklyTarget,
          '${widget.user.id}_studyDailyTarget': _studyDailyTarget,
          '${widget.user.id}_studyWeeklyTarget': _studyWeeklyTarget,
          '${widget.user.id}_chorePoints': _chorePoints,
          '${widget.user.id}_prayerPoints': _prayerPoints,
          '${widget.user.id}_studyPoints': _studyPoints,
        });
        _dataService.updateTask(taskList[index]);
      }
    });
  }

  void _showCongratulationDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yay!', style: AppConstants.subheadingTextStyle),
        content: CongratulatoryWidget(task: task),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  void _redeemPoints() {
    final TextEditingController requestController = TextEditingController();
    final TextEditingController pointsController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Redeem Points',
          style: AppConstants.subheadingTextStyle,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: requestController,
              decoration: const InputDecoration(
                hintText: 'What do you want? (e.g., buy a toy)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: pointsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: 'Points to redeem (e.g., 60)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final requestText = requestController.text;
              final points = int.tryParse(pointsController.text) ?? 0;
              if (requestText.isNotEmpty && points > 0 && points <= _points) {
                final request = {
                  'kidId': widget.user.id,
                  'kidName': widget.user.name,
                  'request': requestText,
                  'points': points,
                };
                final requests = await _dataService.fetchRedemptionRequests();
                requests.add(request);
                await _dataService.saveRedemptionRequests(requests);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Redemption request sent!'),
                    ),
                  );
                }
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid request or insufficient points'),
                  ),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkAndResetDaily() async {
    final lastReset = await _dataService.getLastResetDate(widget.user.id);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastReset == null || lastReset.isBefore(today)) {
      // It's a new day, reset daily counters
      await _resetDailyProgress();
      await _dataService.saveLastResetDate(
          widget.user.id, now.toString() as DateTime);
    }
  }

  Future<void> _resetDailyProgress() async {
    setState(() {
      _choreDailyAchieved = 0;
      _prayerDailyAchieved = 0;
      _studyDailyAchieved = 0;
    });

    await _dataService.saveSettings({
      '${widget.user.id}_choreDailyAchieved': 0,
      '${widget.user.id}_prayerDailyAchieved': 0,
      '${widget.user.id}_studyDailyAchieved': 0,
      // Keep all other settings
      '${widget.user.id}_choreWeeklyAchieved': _choreWeeklyAchieved,
      '${widget.user.id}_prayerWeeklyAchieved': _prayerWeeklyAchieved,
      '${widget.user.id}_studyWeeklyAchieved': _studyWeeklyAchieved,
      '${widget.user.id}_points': _points,
      // ... other settings
    });
  }

  Widget _buildTaskTab(
    List<Task> tasks,
    int dailyAchieved,
    int dailyTarget,
    int weeklyAchieved,
    int weeklyTarget,
  ) {
    final progress = dailyTarget > 0 ? dailyAchieved / dailyTarget : 0.0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Progress', style: AppConstants.subheadingTextStyle),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Daily: $dailyAchieved/$dailyTarget',
                    style: AppConstants.bodyTextStyle,
                  ),
                  Text(
                    'Weekly: $weeklyAchieved/$weeklyTarget',
                    style: AppConstants.bodyTextStyle,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: AppConstants.lightPink,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(AppConstants.primaryPink),
                // Custom gradient (requires custom painter for true gradient)
              ),
            ),
          ),
          const Divider(color: AppConstants.secondaryPink),
          tasks.isEmpty
              ? const Center(
                  child:
                      Text('No tasks yet!', style: AppConstants.bodyTextStyle),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return TaskTile(
                      task: task,
                      onTaskCompletionChanged: _toggleTaskCompletion,
                    );
                  },
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.user.name}'s Dashboard"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: AppConstants.secondaryPink,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Chores'),
            Tab(text: 'Prayers'),
            Tab(text: 'Study'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage(widget.user.avatar),
                  backgroundColor: AppConstants.secondaryPink.withOpacity(0.2),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Points: $_points',
                      style: AppConstants.subheadingTextStyle.copyWith(
                        fontSize: 20,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _redeemPoints,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryPink,
                      ),
                      child: const Text('Redeem Points'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTaskTab(
                  _chores,
                  _choreDailyAchieved,
                  _choreDailyTarget,
                  _choreWeeklyAchieved,
                  _choreWeeklyTarget,
                ),
                _buildTaskTab(
                  _prayers,
                  _prayerDailyAchieved,
                  _prayerDailyTarget,
                  _prayerWeeklyAchieved,
                  _prayerWeeklyTarget,
                ),
                _buildTaskTab(
                  _study,
                  _studyDailyAchieved,
                  _studyDailyTarget,
                  _studyWeeklyAchieved,
                  _studyWeeklyTarget,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
