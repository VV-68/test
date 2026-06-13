import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sf;
import '../models/room_state.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _displayNameController;
  String? _selectedAvatar;
  bool _isEditingName = false;
  bool _isLoading = false;
  
  // Toggle states
  bool _pushNotifications = true;
  bool _hapticFeedback = true;

  // Dietary chips
  final List<String> _dietaryPreferences = ['Vegetarian', 'Gluten-Free', 'Dairy-Free'];

  @override
  void initState() {
    super.initState();
    final state = Provider.of<RoomState>(context, listen: false);
    _displayNameController = TextEditingController(text: state.myDisplayName ?? 'User');
    _selectedAvatar = state.myAvatarUrl;

    if (state.myDisplayName == null) {
      state.loadUserProfile().then((_) {
        if (mounted) {
          setState(() {
            _displayNameController.text = state.myDisplayName ?? 'User';
            _selectedAvatar = state.myAvatarUrl;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfileChanges(RoomState state) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await state.updateUserProfile(
        _displayNameController.text.trim(),
        _selectedAvatar ?? 'https://api.dicebear.com/7.x/bottts/svg?seed=default',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: ${e.toString()}'),
          backgroundColor: AppTheme.nopeRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAvatarPicker(RoomState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardObsidian,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        final List<String> foodAvatars = [
          'assets/images/avatars/avatar_burger.png',
          'assets/images/avatars/avatar_pizza.png',
          'assets/images/avatars/avatar_taco.png',
          'assets/images/avatars/avatar_sushi.png',
          'assets/images/avatars/avatar_donut.png',
          'assets/images/avatars/avatar_dumpling.png',
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose Your Food Avatar 😋',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textWhite,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: foodAvatars.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemBuilder: (context, index) {
                    final avatarPath = foodAvatars[index];
                    final isSelected = _selectedAvatar == avatarPath;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedAvatar = avatarPath;
                        });
                        Navigator.pop(context);
                        _saveProfileChanges(state);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryCoral : AppTheme.borderGray,
                            width: isSelected ? 3.0 : 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryCoral.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            avatarPath,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    final user = sf.Supabase.instance.client.auth.currentUser;
                    setState(() {
                      _selectedAvatar = 'https://api.dicebear.com/7.x/bottts/svg?seed=${user?.id ?? 'default'}';
                    });
                    Navigator.pop(context);
                    _saveProfileChanges(state);
                  },
                  child: const Text(
                    'Use Default Bot Avatar',
                    style: TextStyle(color: AppTheme.primaryCoral, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardObsidian,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppTheme.borderGray),
          ),
          title: const Text('🚪 Log Out'),
          content: const Text('Are you sure you want to log out of Cravit?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: AppTheme.textGray)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
              },
              child: const Text(
                'Log Out',
                style: TextStyle(color: AppTheme.nopeRed, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<RoomState>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        color: AppTheme.bgObsidian,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Avatar & Basic Info Card
                 Container(
                   padding: const EdgeInsets.all(24),
                   decoration: BoxDecoration(
                     color: AppTheme.cardObsidian,
                     borderRadius: BorderRadius.circular(24),
                     border: Border.all(color: AppTheme.borderGray),
                     boxShadow: [
                       BoxShadow(
                         color: Colors.black.withOpacity(0.2),
                         blurRadius: 10,
                         offset: const Offset(0, 4),
                       ),
                     ],
                   ),
                   child: Column(
                     children: [
                       InkWell(
                         onTap: () => _showAvatarPicker(state),
                         borderRadius: BorderRadius.circular(50),
                         child: Stack(
                           children: [
                             CircleAvatar(
                               radius: 50,
                               backgroundColor: AppTheme.cardObsidianLight,
                               child: ClipOval(
                                 child: _selectedAvatar != null && _selectedAvatar!.startsWith('assets/')
                                     ? Image.asset(
                                         _selectedAvatar!,
                                         width: 100,
                                         height: 100,
                                         fit: BoxFit.cover,
                                       )
                                     : Image.network(
                                         _selectedAvatar ?? 'https://api.dicebear.com/7.x/bottts/svg?seed=you',
                                         width: 100,
                                         height: 100,
                                         fit: BoxFit.cover,
                                         errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: AppTheme.primaryCoral, size: 40),
                                       ),
                               ),
                             ),
                             Positioned(
                               bottom: 0,
                               right: 0,
                               child: Container(
                                 padding: const EdgeInsets.all(6),
                                 decoration: const BoxDecoration(
                                   color: AppTheme.primaryCoral,
                                   shape: BoxShape.circle,
                                 ),
                                 child: Icon(
                                   Icons.edit,
                                   size: 16,
                                   color: AppTheme.textWhite,
                                 ),
                               ),
                             ),
                           ],
                         ),
                       ),
                       const SizedBox(height: 16),
                       // Editable Name Field
                       Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           const SizedBox(width: 40), // spacer to center text
                           Expanded(
                             child: _isEditingName
                                 ? TextField(
                                     controller: _displayNameController,
                                     style: TextStyle(
                                       color: AppTheme.textWhite,
                                       fontSize: 22,
                                       fontWeight: FontWeight.bold,
                                     ),
                                     textAlign: TextAlign.center,
                                     decoration: const InputDecoration(
                                       isDense: true,
                                       contentPadding: EdgeInsets.symmetric(vertical: 8),
                                       focusedBorder: UnderlineInputBorder(
                                         borderSide: BorderSide(color: AppTheme.primaryCoral),
                                       ),
                                     ),
                                   )
                                 : Text(
                                     _displayNameController.text.isEmpty ? 'User' : _displayNameController.text,
                                     textAlign: TextAlign.center,
                                     style: TextStyle(
                                       fontSize: 22,
                                       fontWeight: FontWeight.bold,
                                       color: AppTheme.textWhite,
                                     ),
                                   ),
                           ),
                           IconButton(
                             icon: Icon(
                               _isEditingName ? Icons.check : Icons.edit_outlined,
                               color: AppTheme.textGray,
                               size: 20,
                             ),
                             onPressed: () async {
                               if (_isEditingName) {
                                 await _saveProfileChanges(state);
                               }
                               setState(() {
                                 _isEditingName = !_isEditingName;
                               });
                             },
                           ),
                         ],
                       ),
                       Text(
                         '@${state.myUsername ?? 'username'}',
                         style: TextStyle(
                           fontSize: 14,
                           color: AppTheme.textGray,
                         ),
                       ),
                       const SizedBox(height: 20),
                       Divider(color: AppTheme.borderGray, height: 1),
                       const SizedBox(height: 20),
                       
                       // Authenticated Account Status (Uneditable)
                       Row(
                         children: [
                           const Icon(Icons.security, color: AppTheme.primaryCoral, size: 20),
                           const SizedBox(width: 12),
                           Expanded(
                             child: Text(
                               sf.Supabase.instance.client.auth.currentUser?.phone != null
                                   ? 'Phone: ${sf.Supabase.instance.client.auth.currentUser!.phone}'
                                   : 'Logged in Anonymously',
                               style: TextStyle(
                                 color: AppTheme.textWhite,
                                 fontSize: 14,
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                           ),
                         ],
                       ),
                     ],
                   ),
                 ),
                const SizedBox(height: 24),

                // Statistics Grid Dashboard
                Text(
                  'Your Activity 📊',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.4,
                  children: [
                    _buildStatCard('Sessions Joined', '24', Icons.group),
                    _buildStatCard('Matches Found', '18', Icons.favorite),
                    _buildStatCard('Match Rate', '75%', Icons.percent),
                    _buildStatCard('Fav Cuisine', 'Pizza 🍕', Icons.restaurant),
                  ],
                ),
                const SizedBox(height: 24),

                // Dietary Preferences List
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dietary Settings 🥦',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pushNamed('/filters');
                      },
                      child: const Text(
                        'Change',
                        style: TextStyle(color: AppTheme.primaryCoral, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _dietaryPreferences.map((pref) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.cardObsidian,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderGray),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check, color: AppTheme.likeGreen, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            pref,
                            style: TextStyle(color: AppTheme.textWhite, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Settings Switch Card
                Text(
                  'Preferences ⚙️',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardObsidian,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.borderGray),
                  ),
                  child: Column(
                    children: [
                      _buildSwitchTile(
                        title: 'Dark Theme',
                        value: state.isDarkMode,
                        onChanged: (val) {
                          state.toggleThemeMode(val);
                        },
                      ),
                      Divider(color: AppTheme.borderGray, height: 1),
                      _buildSwitchTile(
                        title: 'Push Notifications',
                        value: _pushNotifications,
                        onChanged: (val) => setState(() => _pushNotifications = val),
                      ),
                      Divider(color: AppTheme.borderGray, height: 1),
                      _buildSwitchTile(
                        title: 'Haptic Feedback',
                        value: _hapticFeedback,
                        onChanged: (val) => setState(() => _hapticFeedback = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Logout Action Button
                ElevatedButton(
                  onPressed: _handleLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: AppTheme.nopeRed,
                    side: const BorderSide(color: AppTheme.nopeRed, width: 1.5),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('Log Out'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardObsidian,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: AppTheme.primaryCoral, size: 20),
              Text(
                value,
                style: TextStyle(
                  color: AppTheme.textWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textGray,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(color: AppTheme.textWhite, fontSize: 15, fontWeight: FontWeight.bold),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryCoral,
      activeTrackColor: AppTheme.primaryCoral.withOpacity(0.2),
      inactiveThumbColor: AppTheme.textGray,
      inactiveTrackColor: AppTheme.cardObsidianLight,
    );
  }
}
