import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user.dart';
import '../models/user_type.dart';
import '../models/task.dart';
import '../services/data_service.dart';
import 'kid_dashboard.dart';
import 'parent_setup_screen.dart';
import '../widgets/pin_entry.dart';
import '../utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final DataService _dataService = DataService();
  List<User> _users = [];
  String _parentPin = '1234';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await _dataService.fetchUsers();
    final settings = await _dataService.fetchSettings();
    setState(() {
      _parentPin = settings['pin'] ?? '1234';
      if (users.isEmpty) {
        // Only create a parent profile, no kid profiles
        _users = [
          User(
            id: 'parent',
            name: 'Parent',
            avatar: AppConstants.avatars[2],
            userType: UserType.parent,
          ),
        ];
        _dataService.saveUsers(_users);
      } else {
        _users = users;
      }
    });
  }

  Future<void> _initializePrayers(User kid) async {
    final prayers = [
      Task(
        id: '${kid.id}_prayer_fajr',
        title: 'Fajr',
        category: AppConstants.prayerCategory,
        isCompleted: false,
      ),
      Task(
        id: '${kid.id}_prayer_zuhar',
        title: 'Zuhar',
        category: AppConstants.prayerCategory,
        isCompleted: false,
      ),
      Task(
        id: '${kid.id}_prayer_asar',
        title: 'Asar',
        category: AppConstants.prayerCategory,
        isCompleted: false,
      ),
      Task(
        id: '${kid.id}_prayer_maghrib',
        title: 'Maghrib',
        category: AppConstants.prayerCategory,
        isCompleted: false,
      ),
      Task(
        id: '${kid.id}_prayer_isha',
        title: 'Isha',
        category: AppConstants.prayerCategory,
        isCompleted: false,
      ),
    ];
    for (var prayer in prayers) {
      await _dataService.addTask(prayer);
    }
  }

  void _addKidProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParentSetupScreen(addKidMode: true),
      ),
    ).then((newKid) {
      if (newKid != null) {
        setState(() {
          _users.add(newKid);
        });
        _dataService.saveUsers(_users);
        _initializePrayers(newKid); // Initialize prayers for new kid
      }
    });
  }

  void _editAvatar(User user) {
    String selectedAvatar = user.avatar;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Choose Avatar',
          style: AppConstants.subheadingTextStyle,
        ),
        content: SizedBox(
          width: double.maxFinite,
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
                  selectedAvatar = avatar;
                  final updatedUser = User(
                    id: user.id,
                    name: user.name,
                    avatar: selectedAvatar,
                    userType: user.userType,
                  );
                  setState(() {
                    final index = _users.indexWhere((u) => u.id == user.id);
                    _users[index] = updatedUser;
                  });
                  _dataService.saveUsers(_users);
                  Navigator.pop(context);
                },
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage(avatar),
                  backgroundColor: selectedAvatar == avatar
                      ? AppConstants.primaryPink.withOpacity(0.3)
                      : AppConstants.secondaryPink.withOpacity(0.2),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _editProfile(User user) {
    TextEditingController nameController = TextEditingController(
      text: user.name,
    );
    String selectedAvatar = user.avatar;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Edit Profile',
          style: AppConstants.subheadingTextStyle,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _editAvatar(user); // Open avatar selection
              },
              child: const Text('Change Avatar'),
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
              final updatedUser = User(
                id: user.id,
                name: nameController.text,
                avatar: selectedAvatar,
                userType: user.userType,
              );
              setState(() {
                final index = _users.indexWhere((u) => u.id == user.id);
                _users[index] = updatedUser;
              });
              await _dataService.saveUsers(_users);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated!')),
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _login(User user) {
    if (user.userType == UserType.parent) {
      _showPinInputDialog();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => KidDashboard(user: user)),
      );
    }
  }

  void _showPinInputDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Enter Parent PIN',
            style: AppConstants.subheadingTextStyle,
          ),
          content: PinEntry(
            correctPin: _parentPin,
            onPinEntered: (pin) {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ParentSetupScreen(),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove AppBar to create a full-screen home feel
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppConstants.lightPink.withOpacity(0.8),
              AppConstants.secondaryPink.withOpacity(0.5),
            ],
          ),
          // Optional: Add a subtle background pattern
          image: const DecorationImage(
            image: AssetImage('assets/images/background_pattern.png'),
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                // Creative Header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Text(
                        'Ghumman Kids!',
                        style: GoogleFonts.comicNeue(
                          textStyle: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryPink,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose your profile to start',
                        style: GoogleFonts.comicNeue(
                          textStyle: TextStyle(
                            fontSize: 18,
                            color: AppConstants.primaryPink.withOpacity(0.7),
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.75, // Adjusted for better spacing
                    ),
                    itemCount: _users.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _users.length) {
                        return GestureDetector(
                          onTap: _addKidProfile,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppConstants.primaryPink.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_circle,
                                  size: 50,
                                  color: AppConstants.primaryPink,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Add Kid',
                                  style: GoogleFonts.comicNeue(
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppConstants.primaryPink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final user = _users[index];
                      return Column(
                        children: [
                          GestureDetector(
                            onTap: () => _login(user),
                            onLongPress: user.userType == UserType.kid
                                ? () => _editProfile(user)
                                : null,
                            child: AnimatedScale(
                              scale: 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppConstants.primaryPink
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundImage: AssetImage(user.avatar),
                                  backgroundColor: Colors.white,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppConstants.primaryPink,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            user.name,
                            style: GoogleFonts.comicNeue(
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryPink,
                              ),
                            ),
                          ),
                          if (user.userType == UserType.kid)
                            TextButton(
                              onPressed: () => _editAvatar(user),
                              child: Text(
                                'Change Avatar',
                                style: GoogleFonts.comicNeue(
                                  textStyle: const TextStyle(
                                    fontSize: 12,
                                    color: AppConstants.primaryPink,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
