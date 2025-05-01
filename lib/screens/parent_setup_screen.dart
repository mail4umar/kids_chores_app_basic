import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../models/user_type.dart';
import '../models/task.dart';
import '../services/data_service.dart';
import '../utils/constants.dart';
import 'login_screen.dart';

class ParentSetupScreen extends StatefulWidget {
  final bool addKidMode;
  const ParentSetupScreen({super.key, this.addKidMode = false});
  @override
  State<ParentSetupScreen> createState() => _ParentSetupScreenState();
}

class _ParentSetupScreenState extends State<ParentSetupScreen> {
  final DataService _dataService = DataService();
  String _pin = '1234';
  List<User> _kids = [];
  User? _selectedKid;
  User? _kidToDelete;
  int _choreDailyTarget = 0;
  int _choreWeeklyTarget = 0;
  int _prayerDailyTarget = 0;
  int _prayerWeeklyTarget = 0;
  int _studyDailyTarget = 0;
  int _studyWeeklyTarget = 0;
  int _chorePoints = 2;
  int _prayerPoints = 1;
  int _studyPoints = 2;
  int _reducePoints = 0;
  List<Task> _choreTasks = [];
  List<Task> _studyTasks = [];
  List<Map<String, dynamic>> _redemptionRequests = [];
  final TextEditingController _choreController = TextEditingController();
  final TextEditingController _studyController = TextEditingController();
  final TextEditingController _kidNameController = TextEditingController();
  final TextEditingController _reducePointsController = TextEditingController();
  String _selectedChoreIcon = AppConstants.choreIconNames[0];
  String _selectedAvatar = AppConstants.avatars[0];
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final users = await _dataService.fetchUsers();
    final settings = await _dataService.fetchSettings();
    final tasks = await _dataService.fetchTasks();
    final redemptions = await _dataService.fetchRedemptionRequests();
    setState(() {
      _pin = settings['pin'] ?? '1234';
      _kids = users.where((u) => u.userType == UserType.kid).toList();
      _redemptionRequests = redemptions;
      if (_kids.isNotEmpty && !widget.addKidMode) {
        _selectedKid = _kids.first;
        _loadKidData(_selectedKid!.id, settings, tasks);
      }
    });
  }

  void _loadKidData(
      String kidId, Map<String, dynamic> settings, List<Task> tasks) {
    _choreDailyTarget = settings['${kidId}_choreDailyTarget'] ?? 0;
    _choreWeeklyTarget = settings['${kidId}_choreWeeklyTarget'] ?? 0;
    _prayerDailyTarget = settings['${kidId}_prayerDailyTarget'] ?? 0;
    _prayerWeeklyTarget = settings['${kidId}_prayerWeeklyTarget'] ?? 0;
    _studyDailyTarget = settings['${kidId}_studyDailyTarget'] ?? 0;
    _studyWeeklyTarget = settings['${kidId}_studyWeeklyTarget'] ?? 0;
    _chorePoints = settings['${kidId}_chorePoints'] ?? 2;
    _prayerPoints = settings['${kidId}_prayerPoints'] ?? 1;
    _studyPoints = settings['${kidId}_studyPoints'] ?? 2;
    _choreTasks = tasks
        .where((t) =>
            t.id.startsWith('${kidId}_chore_') &&
            t.category == AppConstants.choreCategory)
        .toList();
    _studyTasks = tasks
        .where((t) =>
            t.id.startsWith('${kidId}_study_') &&
            t.category == AppConstants.studyCategory)
        .toList();
  }

  void _addChore() {
    if (_choreController.text.isNotEmpty && _selectedKid != null) {
      final task = Task(
        id: '${_selectedKid!.id}_chore_${const Uuid().v4()}',
        title: _choreController.text,
        category: AppConstants.choreCategory,
        isCompleted: false,
        iconName: _selectedChoreIcon,
      );
      setState(() {
        _choreTasks.add(task);
        _choreController.clear();
        _selectedChoreIcon = AppConstants.choreIconNames[0];
      });
      _dataService.addTask(task);
    }
  }

  void _removeChore(Task task) {
    setState(() {
      _choreTasks.removeWhere((t) => t.id == task.id);
    });
    _dataService.addTask(task);
  }

  void _addStudy() {
    if (_studyController.text.isNotEmpty && _selectedKid != null) {
      final task = Task(
        id: '${_selectedKid!.id}_study_${const Uuid().v4()}',
        title: _studyController.text,
        category: AppConstants.studyCategory,
        isCompleted: false,
      );
      setState(() {
        _studyTasks.add(task);
        _studyController.clear();
      });
      _dataService.addTask(task);
    }
  }

  void _removeStudy(Task task) {
    setState(() {
      _studyTasks.removeWhere((t) => t.id == task.id);
    });
    _dataService.addTask(task);
  }

  void _deleteKid() {
    if (_kidToDelete != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Deletion',
              style: AppConstants.subheadingTextStyle),
          content: Text(
              'Are you sure you want to delete ${_kidToDelete!.name}\'s profile?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _dataService.deleteKidData(_kidToDelete!.id);
                setState(() {
                  _kids.removeWhere((k) => k.id == _kidToDelete!.id);
                  _selectedKid = _kids.isNotEmpty ? _kids.first : null;
                  _kidToDelete = null;
                  if (_selectedKid != null) {
                    _loadKidData(_selectedKid!.id, {}, []);
                  } else {
                    _choreTasks.clear();
                    _studyTasks.clear();
                    _choreDailyTarget = 0;
                    _choreWeeklyTarget = 0;
                    _prayerDailyTarget = 0;
                    _prayerWeeklyTarget = 0;
                    _studyDailyTarget = 0;
                    _studyWeeklyTarget = 0;
                    _chorePoints = 2;
                    _prayerPoints = 1;
                    _studyPoints = 2;
                  }
                });
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('${_kidToDelete!.name}\'s profile deleted')),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }
  }

  void _handleRedemptionRequest(
      Map<String, dynamic> request, bool accept) async {
    final kidId = request['kidId'];
    final points = request['points'] as int;
    setState(() {
      _redemptionRequests.remove(request);
    });
    await _dataService.saveRedemptionRequests(_redemptionRequests);
    if (accept) {
      final settings = await _dataService.fetchSettings();
      final currentPoints = settings['${kidId}_points'] ?? 0;
      final newPoints =
          (currentPoints - points).clamp(0, double.infinity).toInt();
      settings['${kidId}_points'] = newPoints;
      await _dataService.saveSettings(settings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Approved ${request['request']} for ${request['kidName']}')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Rejected ${request['request']} for ${request['kidName']}')),
        );
      }
    }
  }

  void _reduceKidPoints() async {
    if (_selectedKid != null && _reducePoints > 0) {
      final settings = await _dataService.fetchSettings();
      final currentPoints = settings['${_selectedKid!.id}_points'] ?? 0;
      final newPoints =
          (currentPoints - _reducePoints).clamp(0, double.infinity).toInt();
      settings['${_selectedKid!.id}_points'] = newPoints;
      await _dataService.saveSettings(settings);
      setState(() {
        _reducePointsController.clear();
        _reducePoints = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Reduced ${_selectedKid!.name}\'s points by $_reducePoints')),
        );
      }
    }
  }

  Future<void> _saveSetup() async {
    if (widget.addKidMode) {
      if (_kidNameController.text.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a name for the kid')),
          );
        }
        return;
      }
      final newKid = User(
        id: const Uuid().v4(),
        name: _kidNameController.text,
        avatar: _selectedAvatar,
        userType: UserType.kid,
      );
      if (mounted) {
        Navigator.pop(context, newKid);
      }
      return;
    }
    if (_selectedKid != null) {
      for (var task in _choreTasks) {
        await _dataService.addTask(task);
      }
      for (var task in _studyTasks) {
        await _dataService.addTask(task);
      }
      final settings = await _dataService.fetchSettings();
      settings['pin'] = _pin;
      settings['${_selectedKid!.id}_choreDailyTarget'] = _choreDailyTarget;
      settings['${_selectedKid!.id}_choreWeeklyTarget'] = _choreWeeklyTarget;
      settings['${_selectedKid!.id}_prayerDailyTarget'] = _prayerDailyTarget;
      settings['${_selectedKid!.id}_prayerWeeklyTarget'] = _prayerWeeklyTarget;
      settings['${_selectedKid!.id}_studyDailyTarget'] = _studyDailyTarget;
      settings['${_selectedKid!.id}_studyWeeklyTarget'] = _studyWeeklyTarget;
      settings['${_selectedKid!.id}_chorePoints'] = _chorePoints;
      settings['${_selectedKid!.id}_prayerPoints'] = _prayerPoints;
      settings['${_selectedKid!.id}_studyPoints'] = _studyPoints;
      settings['${_selectedKid!.id}_points'] =
          settings['${_selectedKid!.id}_points'] ?? 0;
      await _dataService.saveSettings(settings);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Setup saved successfully!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.addKidMode ? 'Add New Kid' : 'Parent Setup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.addKidMode) ...[
                const Text('Kid Name:',
                    style: AppConstants.subheadingTextStyle),
                TextField(
                  controller: _kidNameController,
                  decoration:
                      const InputDecoration(hintText: 'Enter kid\'s name'),
                ),
                const SizedBox(height: 20),
                const Text('Kid Avatar:',
                    style: AppConstants.subheadingTextStyle),
                SizedBox(
                  height: 100,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: AppConstants.avatars.length,
                    itemBuilder: (context, index) {
                      final avatar = AppConstants.avatars[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAvatar = avatar;
                          });
                        },
                        child: CircleAvatar(
                          radius: 30,
                          backgroundImage: AssetImage(avatar),
                          backgroundColor: _selectedAvatar == avatar
                              ? AppConstants.primaryPink.withValues(alpha: 0.3)
                              : AppConstants.secondaryPink
                                  .withValues(alpha: 0.2),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: _saveSetup,
                    child: const Text('Add Kid'),
                  ),
                ),
              ] else ...[
                const Text('Set PIN:', style: AppConstants.subheadingTextStyle),
                TextField(
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  onChanged: (value) => _pin = value,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration:
                      const InputDecoration(hintText: 'Enter 4-digit PIN'),
                ),
                const SizedBox(height: 20),
                const Text('Select Kid:',
                    style: AppConstants.subheadingTextStyle),
                DropdownButton<User>(
                  value: _selectedKid,
                  hint: const Text('Choose a kid'),
                  isExpanded: true,
                  onChanged: (User? kid) {
                    if (kid != null) {
                      setState(() {
                        _selectedKid = kid;
                        _loadKidData(kid.id, {}, []);
                      });
                    }
                  },
                  items: _kids.map((kid) {
                    return DropdownMenuItem(
                      value: kid,
                      child: Text(kid.name),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text('Delete Kid Profile:',
                    style: AppConstants.subheadingTextStyle),
                DropdownButton<User>(
                  value: _kidToDelete,
                  hint: const Text('Select kid to delete'),
                  isExpanded: true,
                  onChanged: (User? kid) {
                    setState(() {
                      _kidToDelete = kid;
                    });
                  },
                  items: _kids.map((kid) {
                    return DropdownMenuItem(
                      value: kid,
                      child: Text(kid.name),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Center(
                  child: ElevatedButton(
                    onPressed: _kidToDelete != null ? _deleteKid : null,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Delete Selected Kid'),
                  ),
                ),
                if (_selectedKid != null) ...[
                  const SizedBox(height: 20),
                  const Text('Chore Settings:',
                      style: AppConstants.subheadingTextStyle),
                  TextField(
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        _choreDailyTarget = int.tryParse(value) ?? 0,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration:
                        const InputDecoration(hintText: 'Chore daily target'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        _choreWeeklyTarget = int.tryParse(value) ?? 0,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration:
                        const InputDecoration(hintText: 'Chore weekly target'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        _chorePoints = int.tryParse(value) ?? 2,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                        hintText: 'Points per chore (e.g., 2)'),
                  ),
                  const SizedBox(height: 20),
                  const Text('Prayer Settings:',
                      style: AppConstants.subheadingTextStyle),
                  TextField(
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        _prayerDailyTarget = int.tryParse(value) ?? 0,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration:
                        const InputDecoration(hintText: 'Prayer daily target'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        _prayerWeeklyTarget = int.tryParse(value) ?? 0,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration:
                        const InputDecoration(hintText: 'Prayer weekly target'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        _prayerPoints = int.tryParse(value) ?? 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                        hintText: 'Points per prayer (e.g., 1)'),
                  ),
                  const SizedBox(height: 20),
                  const Text('Study Settings:',
                      style: AppConstants.subheadingTextStyle),
                  TextField(
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        _studyDailyTarget = int.tryParse(value) ?? 0,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration:
                        const InputDecoration(hintText: 'Study daily target'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        _studyWeeklyTarget = int.tryParse(value) ?? 0,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration:
                        const InputDecoration(hintText: 'Study weekly target'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        _studyPoints = int.tryParse(value) ?? 2,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                        hintText: 'Points per study task (e.g., 2)'),
                  ),
                  const SizedBox(height: 20),
                  const Text('Chores:',
                      style: AppConstants.subheadingTextStyle),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _choreController,
                          decoration:
                              const InputDecoration(hintText: 'Enter chore'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        value: _selectedChoreIcon,
                        onChanged: (value) {
                          setState(() {
                            _selectedChoreIcon = value!;
                          });
                        },
                        items: AppConstants.choreIconNames.map((icon) {
                          return DropdownMenuItem(
                            value: icon,
                            child: Text(icon),
                          );
                        }).toList(),
                      ),
                      IconButton(
                          icon: const Icon(Icons.add), onPressed: _addChore),
                    ],
                  ),
                  if (_choreTasks.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ..._choreTasks.map((task) => ListTile(
                          leading: Icon(AppConstants.choreIcons[task.iconName],
                              color: AppConstants.primaryPink),
                          title: Text(task.title),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete,
                                color: AppConstants.primaryPink),
                            onPressed: () => _removeChore(task),
                          ),
                        )),
                  ],
                  const SizedBox(height: 20),
                  const Text('Study:', style: AppConstants.subheadingTextStyle),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _studyController,
                          decoration: const InputDecoration(
                              hintText: 'Enter study task'),
                        ),
                      ),
                      IconButton(
                          icon: const Icon(Icons.add), onPressed: _addStudy),
                    ],
                  ),
                  if (_studyTasks.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ..._studyTasks.map((task) => ListTile(
                          title: Text(task.title),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete,
                                color: AppConstants.primaryPink),
                            onPressed: () => _removeStudy(task),
                          ),
                        )),
                  ],
                  const SizedBox(height: 20),
                  const Text('Reduce Points:',
                      style: AppConstants.subheadingTextStyle),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _reducePointsController,
                          keyboardType: TextInputType.number,
                          onChanged: (value) =>
                              _reducePoints = int.tryParse(value) ?? 0,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: const InputDecoration(
                              hintText: 'Enter points to reduce'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _reduceKidPoints,
                        child: const Text('Reduce'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Redemption Requests:',
                      style: AppConstants.subheadingTextStyle),
                  if (_redemptionRequests.isEmpty)
                    const Text('No pending requests',
                        style: AppConstants.bodyTextStyle)
                  else
                    ..._redemptionRequests.map((request) {
                      if (_kids.any((kid) => kid.id == request['kidId'])) {
                        return ListTile(
                          title: Text(
                              '${request['kidName']}: ${request['request']} (${request['points']} points)'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check,
                                    color: Colors.green),
                                onPressed: () =>
                                    _handleRedemptionRequest(request, true),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.close, color: Colors.red),
                                onPressed: () =>
                                    _handleRedemptionRequest(request, false),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: _saveSetup,
                      child: const Text('Save Setup'),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _choreController.dispose();
    _studyController.dispose();
    _kidNameController.dispose();
    _reducePointsController.dispose();
    super.dispose();
  }
}
