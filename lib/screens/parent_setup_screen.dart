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
  final _choreController = TextEditingController();
  final _studyController = TextEditingController();
  final _kidNameController = TextEditingController();
  final _reducePointsController = TextEditingController();

  String _pin = '1234';
  String _selectedAvatar = AppConstants.avatars[0];
  String _selectedChoreIcon = AppConstants.choreIconNames[0];
  List<User> _kids = [];
  User? _selectedKid;
  User? _kidToDelete;
  List<Task> _choreTasks = [];
  List<Task> _studyTasks = [];
  List<Map<String, dynamic>> _redemptionRequests = [];
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _choreController.dispose();
    _studyController.dispose();
    _kidNameController.dispose();
    _reducePointsController.dispose();
    super.dispose();
  }

  /// Loads initial data for kids, settings, tasks, and redemption requests.
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

  /// Loads kid-specific data such as tasks and settings.
  void _loadKidData(
      String kidId, Map<String, dynamic> settings, List<Task> tasks) {
    setState(() {
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
    });
  }

  /// Adds a new chore for the selected kid.
  void _addChore() {
    if (_choreController.text.isEmpty || _selectedKid == null) return;

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

  /// Removes a chore from the selected kid's tasks.
  void _removeChore(Task task) {
    setState(() {
      _choreTasks.removeWhere((t) => t.id == task.id);
    });
    _dataService
        .removeTask(task.id); // Ensure removeTask is implemented in DataService
  }

  /// Adds a new study task for the selected kid.
  void _addStudy() {
    if (_studyController.text.isEmpty || _selectedKid == null) return;

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

  /// Removes a study task from the selected kid's tasks.
  void _removeStudy(Task task) {
    setState(() {
      _studyTasks.removeWhere((t) => t.id == task.id);
    });
    _dataService
        .removeTask(task.id); // Ensure removeTask is implemented in DataService
  }

  /// Shows a confirmation dialog to delete a kid's profile.
  void _deleteKid() {
    if (_kidToDelete == null) return;

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
                _kidToDelete = null;
                _selectedKid = _kids.isNotEmpty ? _kids.first : null;
                if (_selectedKid == null) {
                  _resetKidData();
                } else {
                  _loadKidData(_selectedKid!.id, {}, []);
                }
              });
              Navigator.pop(context);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('${_kidToDelete!.name}\'s profile deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Resets kid-specific data when no kids are selected.
  void _resetKidData() {
    _choreTasks = [];
    _studyTasks = [];
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

  /// Handles redemption requests (approve or reject).
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
      settings['${kidId}_points'] =
          (currentPoints - points).clamp(0, double.infinity).toInt();
      await _dataService.saveSettings(settings);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${accept ? 'Approved' : 'Rejected'} ${request['request']} for ${request['kidName']}',
        ),
      ),
    );
  }

  /// Reduces points for the selected kid.
  void _reduceKidPoints() async {
    if (_selectedKid == null || _reducePoints <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a kid and enter valid points')),
      );
      return;
    }

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

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Reduced ${_selectedKid!.name}\'s points by $_reducePoints')),
    );
  }

  /// Saves the setup (either a new kid or current settings).
  Future<void> _saveSetup() async {
    if (widget.addKidMode) {
      if (_kidNameController.text.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a name for the kid')),
        );
        return;
      }

      final newKid = User(
        id: const Uuid().v4(),
        name: _kidNameController.text,
        avatar: _selectedAvatar,
        userType: UserType.kid,
      );

      await _dataService.saveUsers([..._kids, newKid]);
      if (!mounted) return;
      Navigator.pop(context, newKid);
      return;
    }

    if (_selectedKid != null) {
      for (final task in _choreTasks) {
        await _dataService.addTask(task);
      }
      for (final task in _studyTasks) {
        await _dataService.addTask(task);
      }

      final settings = await _dataService.fetchSettings();
      settings.addAll({
        'pin': _pin,
        '${_selectedKid!.id}_choreDailyTarget': _choreDailyTarget,
        '${_selectedKid!.id}_choreWeeklyTarget': _choreWeeklyTarget,
        '${_selectedKid!.id}_prayerDailyTarget': _prayerDailyTarget,
        '${_selectedKid!.id}_prayerWeeklyTarget': _prayerWeeklyTarget,
        '${_selectedKid!.id}_studyDailyTarget': _studyDailyTarget,
        '${_selectedKid!.id}_studyWeeklyTarget': _studyWeeklyTarget,
        '${_selectedKid!.id}_chorePoints': _chorePoints,
        '${_selectedKid!.id}_prayerPoints': _prayerPoints,
        '${_selectedKid!.id}_studyPoints': _studyPoints,
        '${_selectedKid!.id}_points':
            settings['${_selectedKid!.id}_points'] ?? 0,
      });

      await _dataService.saveSettings(settings);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Setup saved successfully')),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
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
                _buildSectionTitle('Kid Name'),
                TextField(
                  controller: _kidNameController,
                  decoration:
                      const InputDecoration(hintText: 'Enter kid\'s name'),
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Kid Avatar'),
                _buildAvatarGrid(),
                const SizedBox(height: 30),
                _buildSaveButton('Add Kid'),
              ] else ...[
                _buildSectionTitle('Set PIN'),
                _buildPinField(),
                const SizedBox(height: 20),
                _buildSectionTitle('Select Kid'),
                _buildKidDropdown(),
                const SizedBox(height: 20),
                _buildSectionTitle('Delete Kid Profile'),
                _buildDeleteKidDropdown(),
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
                  _buildSettingsSection(),
                  _buildChoreSection(),
                  _buildStudySection(),
                  _buildReducePointsSection(),
                  _buildRedemptionRequestsSection(),
                  const SizedBox(height: 30),
                  _buildSaveButton('Save Setup'),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a section title with consistent styling.
  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppConstants.subheadingTextStyle);
  }

  /// Builds the PIN input field.
  Widget _buildPinField() {
    return TextField(
      keyboardType: TextInputType.number,
      obscureText: true,
      maxLength: 4,
      onChanged: (value) => _pin = value,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(hintText: 'Enter 4-digit PIN'),
    );
  }

  /// Builds the kid selection dropdown.
  Widget _buildKidDropdown() {
    return DropdownButton<User>(
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
        return DropdownMenuItem(value: kid, child: Text(kid.name));
      }).toList(),
    );
  }

  /// Builds the delete kid dropdown.
  Widget _buildDeleteKidDropdown() {
    return DropdownButton<User>(
      value: _kidToDelete,
      hint: const Text('Select kid to delete'),
      isExpanded: true,
      onChanged: (User? kid) => setState(() => _kidToDelete = kid),
      items: _kids.map((kid) {
        return DropdownMenuItem(value: kid, child: Text(kid.name));
      }).toList(),
    );
  }

  /// Builds the avatar selection grid for adding a new kid.
  Widget _buildAvatarGrid() {
    return SizedBox(
      height: 100,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: AppConstants.avatars.length,
        itemBuilder: (context, index) {
          final avatar = AppConstants.avatars[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedAvatar = avatar),
            child: CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage(avatar),
              backgroundColor: _selectedAvatar == avatar
                  ? AppConstants.primaryPink.withValues(alpha: 0.3)
                  : AppConstants.secondaryPink.withValues(alpha: 0.2),
            ),
          );
        },
      ),
    );
  }

  /// Builds the settings section for chores, prayers, and study.
  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Chore Settings'),
        _buildNumberField(
            'Chore daily target', (value) => _choreDailyTarget = value),
        _buildNumberField(
            'Chore weekly target', (value) => _choreWeeklyTarget = value),
        _buildNumberField(
            'Points per chore (e.g., 2)', (value) => _chorePoints = value,
            defaultValue: 2),
        const SizedBox(height: 20),
        _buildSectionTitle('Prayer Settings'),
        _buildNumberField(
            'Prayer daily target', (value) => _prayerDailyTarget = value),
        _buildNumberField(
            'Prayer weekly target', (value) => _prayerWeeklyTarget = value),
        _buildNumberField(
            'Points per prayer (e.g., 1)', (value) => _prayerPoints = value,
            defaultValue: 1),
        const SizedBox(height: 20),
        _buildSectionTitle('Study Settings'),
        _buildNumberField(
            'Study daily target', (value) => _studyDailyTarget = value),
        _buildNumberField(
            'Study weekly target', (value) => _studyWeeklyTarget = value),
        _buildNumberField(
            'Points per study task (e.g., 2)', (value) => _studyPoints = value,
            defaultValue: 2),
      ],
    );
  }

  /// Builds a number input field with a callback to update state.
  Widget _buildNumberField(String hint, void Function(int) onChanged,
      {int defaultValue = 0}) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        keyboardType: TextInputType.number,
        onChanged: (value) => onChanged(int.tryParse(value) ?? defaultValue),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(hintText: hint),
      ),
    );
  }

  /// Builds the chore input section.
  Widget _buildChoreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildSectionTitle('Chores'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _choreController,
                decoration: const InputDecoration(hintText: 'Enter chore'),
              ),
            ),
            const SizedBox(width: 10),
            DropdownButton<String>(
              value: _selectedChoreIcon,
              onChanged: (value) => setState(() => _selectedChoreIcon = value!),
              items: AppConstants.choreIconNames
                  .map((icon) =>
                      DropdownMenuItem(value: icon, child: Text(icon)))
                  .toList(),
            ),
            IconButton(icon: const Icon(Icons.add), onPressed: _addChore),
          ],
        ),
        if (_choreTasks.isNotEmpty)
          ..._choreTasks.map(
            (task) => ListTile(
              leading: Icon(AppConstants.choreIcons[task.iconName],
                  color: AppConstants.primaryPink),
              title: Text(task.title),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: AppConstants.primaryPink),
                onPressed: () => _removeChore(task),
              ),
            ),
          ),
      ],
    );
  }

  /// Builds the study input section.
  Widget _buildStudySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildSectionTitle('Study'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _studyController,
                decoration: const InputDecoration(hintText: 'Enter study task'),
              ),
            ),
            IconButton(icon: const Icon(Icons.add), onPressed: _addStudy),
          ],
        ),
        if (_studyTasks.isNotEmpty)
          ..._studyTasks.map(
            (task) => ListTile(
              title: Text(task.title),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: AppConstants.primaryPink),
                onPressed: () => _removeStudy(task),
              ),
            ),
          ),
      ],
    );
  }

  /// Builds the reduce points section.
  Widget _buildReducePointsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildSectionTitle('Reduce Points'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _reducePointsController,
                keyboardType: TextInputType.number,
                onChanged: (value) => _reducePoints = int.tryParse(value) ?? 0,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration:
                    const InputDecoration(hintText: 'Enter points to reduce'),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
                onPressed: _reduceKidPoints, child: const Text('Reduce')),
          ],
        ),
      ],
    );
  }

  /// Builds the redemption requests section.
  Widget _buildRedemptionRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildSectionTitle('Redemption Requests'),
        if (_redemptionRequests.isEmpty)
          const Text('No pending requests', style: AppConstants.bodyTextStyle)
        else
          ..._redemptionRequests
              .where(
                  (request) => _kids.any((kid) => kid.id == request['kidId']))
              .map(
                (request) => ListTile(
                  title: Text(
                      '${request['kidName']}: ${request['request']} (${request['points']} points)'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () =>
                            _handleRedemptionRequest(request, true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () =>
                            _handleRedemptionRequest(request, false),
                      ),
                    ],
                  ),
                ),
              ),
      ],
    );
  }

  /// Builds the save button with a custom label.
  Widget _buildSaveButton(String label) {
    return Center(
      child: ElevatedButton(
        onPressed: _saveSetup,
        child: Text(label),
      ),
    );
  }
}
