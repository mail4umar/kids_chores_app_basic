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
  final _addPointsController = TextEditingController();

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
  int _addPoints = 0;
  bool _isAddingPoints = true;

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
    _addPointsController.dispose();
    super.dispose();
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

  void _removeChore(Task task) {
    setState(() {
      _choreTasks.removeWhere((t) => t.id == task.id);
    });
    _dataService.removeTask(task.id);
  }

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

  void _removeStudy(Task task) {
    setState(() {
      _studyTasks.removeWhere((t) => t.id == task.id);
    });
    _dataService.removeTask(task.id);
  }

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

  Future<void> _addKidPoints() async {
    if (_selectedKid == null || _addPoints <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a kid and enter valid points')),
      );
      return;
    }

    final settings = await _dataService.fetchSettings();
    final currentPoints = settings['${_selectedKid!.id}_points'] ?? 0;
    final newPoints = currentPoints + _addPoints;

    settings['${_selectedKid!.id}_points'] = newPoints;
    await _dataService.saveSettings(settings);

    setState(() {
      _addPointsController.clear();
      _addPoints = 0;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Added $_addPoints points to ${_selectedKid!.name}\'s account')),
    );
  }

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
        title: Text(
          widget.addKidMode ? 'Add New Kid' : 'Parent Setup',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppConstants.primaryPink.withOpacity(0.8),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppConstants.primaryPink.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.addKidMode) ...[
                  _buildSectionCard(
                    title: 'Kid Profile',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Kid Name'),
                        _buildTextField(
                          controller: _kidNameController,
                          hint: 'Enter kid\'s name',
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 20),
                        _buildSectionTitle('Kid Avatar'),
                        _buildAvatarGrid(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildSaveButton('Add Kid'),
                ] else ...[
                  _buildSectionCard(
                    title: 'Security',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Set PIN'),
                        _buildPinField(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'Kid Management',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Select Kid'),
                        _buildKidDropdown(),
                        const SizedBox(height: 20),
                        _buildSectionTitle('Delete Kid Profile'),
                        _buildDeleteKidDropdown(),
                        const SizedBox(height: 10),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _kidToDelete != null ? _deleteKid : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('Delete Selected Kid'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedKid != null) ...[
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Kid Settings',
                      content: _buildSettingsSection(),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Task Management',
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildChoreSection(),
                          const Divider(height: 30),
                          _buildStudySection(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Point Management',
                      content: _buildPointManagementSection(),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Requests',
                      content: _buildRedemptionRequestsSection(),
                    ),
                    const SizedBox(height: 30),
                    _buildSaveButton('Save Setup'),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget content}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryPink,
              ),
            ),
            const Divider(height: 24),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: AppConstants.subheadingTextStyle.copyWith(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon:
            icon != null ? Icon(icon, color: AppConstants.primaryPink) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppConstants.primaryPink),
        ),
      ),
    );
  }

  Widget _buildPinField() {
    return TextField(
      keyboardType: TextInputType.number,
      obscureText: true,
      maxLength: 4,
      onChanged: (value) => _pin = value,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        hintText: 'Enter 4-digit PIN',
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: Icon(Icons.lock, color: AppConstants.primaryPink),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppConstants.primaryPink),
        ),
      ),
    );
  }

  Widget _buildKidDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButton<User>(
        value: _selectedKid,
        hint: const Text('Choose a kid'),
        isExpanded: true,
        underline: const SizedBox(),
        icon:
            const Icon(Icons.arrow_drop_down, color: AppConstants.primaryPink),
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
      ),
    );
  }

  Widget _buildDeleteKidDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButton<User>(
        value: _kidToDelete,
        hint: const Text('Select kid to delete'),
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.red),
        onChanged: (User? kid) => setState(() => _kidToDelete = kid),
        items: _kids.map((kid) {
          return DropdownMenuItem(value: kid, child: Text(kid.name));
        }).toList(),
      ),
    );
  }

  Widget _buildAvatarGrid() {
    return SizedBox(
      width: double.infinity,
      height: 200,
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
            onTap: () {
              setState(() {
                _selectedAvatar = avatar;
              });
            },
            child: CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage(avatar),
              backgroundColor: _selectedAvatar == avatar
                  ? AppConstants.primaryPink.withOpacity(0.3)
                  : AppConstants.secondaryPink.withOpacity(0.2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Chore Settings'),
        _buildNumberField('Chore daily target',
            (value) => _choreDailyTarget = value, Icons.calendar_today),
        _buildNumberField('Chore weekly target',
            (value) => _choreWeeklyTarget = value, Icons.view_week),
        _buildNumberField('Points per chore (e.g., 2)',
            (value) => _chorePoints = value, Icons.stars, 2),
        const SizedBox(height: 20),
        _buildSectionTitle('Prayer Settings'),
        _buildNumberField('Prayer daily target',
            (value) => _prayerDailyTarget = value, Icons.calendar_today),
        _buildNumberField('Prayer weekly target',
            (value) => _prayerWeeklyTarget = value, Icons.view_week),
        _buildNumberField('Points per prayer (e.g., 1)',
            (value) => _prayerPoints = value, Icons.stars, 1),
        const SizedBox(height: 20),
        _buildSectionTitle('Study Settings'),
        _buildNumberField('Study daily target',
            (value) => _studyDailyTarget = value, Icons.calendar_today),
        _buildNumberField('Study weekly target',
            (value) => _studyWeeklyTarget = value, Icons.view_week),
        _buildNumberField('Points per study task (e.g., 2)',
            (value) => _studyPoints = value, Icons.stars, 2),
      ],
    );
  }

  Widget _buildNumberField(
      String hint, void Function(int) onChanged, IconData icon,
      [int defaultValue = 0]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        keyboardType: TextInputType.number,
        onChanged: (value) => onChanged(int.tryParse(value) ?? defaultValue),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.grey[50],
          prefixIcon: Icon(icon, color: AppConstants.primaryPink),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppConstants.primaryPink),
          ),
        ),
      ),
    );
  }

  Widget _buildChoreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Chores'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _choreController,
                decoration: InputDecoration(
                  hintText: 'Enter chore',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppConstants.primaryPink),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButton<String>(
                value: _selectedChoreIcon,
                underline: const SizedBox(),
                onChanged: (value) =>
                    setState(() => _selectedChoreIcon = value!),
                items: AppConstants.choreIconNames
                    .map((icon) =>
                        DropdownMenuItem(value: icon, child: Text(icon)))
                    .toList(),
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle, color: AppConstants.primaryPink),
              onPressed: _addChore,
            ),
          ],
        ),
        if (_choreTasks.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _choreTasks.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final task = _choreTasks[index];
                return ListTile(
                  leading: Icon(AppConstants.choreIcons[task.iconName],
                      color: AppConstants.primaryPink),
                  title: Text(task.title),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete,
                        color: AppConstants.primaryPink),
                    onPressed: () => _removeChore(task),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildStudySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Study'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _studyController,
                decoration: InputDecoration(
                  hintText: 'Enter study task',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppConstants.primaryPink),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle, color: AppConstants.primaryPink),
              onPressed: _addStudy,
            ),
          ],
        ),
        if (_studyTasks.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _studyTasks.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final task = _studyTasks[index];
                return ListTile(
                  leading:
                      const Icon(Icons.book, color: AppConstants.primaryPink),
                  title: Text(task.title),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete,
                        color: AppConstants.primaryPink),
                    onPressed: () => _removeStudy(task),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPointManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Manage kid\'s points',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        if (_kids.isEmpty)
          const Text('Add a kid first to manage points')
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKidDropdown(),
              const SizedBox(height: 12),

              // Points mode toggle
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isAddingPoints = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isAddingPoints
                            ? AppConstants.primaryGreen
                            : Colors.grey.shade300,
                        foregroundColor:
                            _isAddingPoints ? Colors.white : Colors.black87,
                      ),
                      child: const Text('Add Points'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isAddingPoints = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !_isAddingPoints
                            ? Colors.redAccent
                            : Colors.grey.shade300,
                        foregroundColor:
                            !_isAddingPoints ? Colors.white : Colors.black87,
                      ),
                      child: const Text('Reduce Points'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Points input field
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _isAddingPoints
                          ? _addPointsController
                          : _reducePointsController,
                      decoration: InputDecoration(
                        hintText: _isAddingPoints
                            ? 'Enter points to add'
                            : 'Enter points to reduce',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(
                          _isAddingPoints
                              ? Icons.add_circle_outline
                              : Icons.remove_circle_outline,
                          color: _isAddingPoints
                              ? AppConstants.primaryGreen
                              : Colors.redAccent,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        setState(() {
                          if (_isAddingPoints) {
                            _addPoints = int.tryParse(value) ?? 0;
                          } else {
                            _reducePoints = int.tryParse(value) ?? 0;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed:
                        _isAddingPoints ? _addKidPoints : _reduceKidPoints,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAddingPoints
                          ? AppConstants.primaryGreen
                          : Colors.redAccent,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                    child: Text(
                      _isAddingPoints ? 'Add' : 'Reduce',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildRedemptionRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Redemption Requests'),
        if (_redemptionRequests.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Text(
              'No pending requests',
              style: AppConstants.bodyTextStyle,
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemCount: _redemptionRequests
                  .where((request) =>
                      _kids.any((kid) => kid.id == request['kidId']))
                  .length,
              itemBuilder: (context, index) {
                final request = _redemptionRequests
                    .where((request) =>
                        _kids.any((kid) => kid.id == request['kidId']))
                    .toList()[index];
                return ListTile(
                  leading: const Icon(Icons.card_giftcard,
                      color: AppConstants.primaryPink),
                  title: Text(
                    '${request['kidName']}: ${request['request']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${request['points']} points'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () =>
                            _handleRedemptionRequest(request, true),
                        tooltip: 'Approve',
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () =>
                            _handleRedemptionRequest(request, false),
                        tooltip: 'Reject',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSaveButton(String label) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _saveSetup,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          backgroundColor: AppConstants.primaryPink,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.save),
        label: Text(label),
      ),
    );
  }
}
