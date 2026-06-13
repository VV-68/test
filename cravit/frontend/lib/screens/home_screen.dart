import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room_state.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RoomState>(context, listen: false).loadUserProfile();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _handleCreateRoom(RoomState state) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryCoral)),
    );
    await state.createRoom();
    if (mounted) {
      Navigator.of(context).pop(); // Dismiss loading spinner
      Navigator.of(context).pushNamed('/filters');
    }
  }

  void _handleJoinRoom(RoomState state) async {
    if (_formKey.currentState!.validate()) {
      final code = _codeController.text.trim();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryCoral)),
      );
      final success = await state.joinRoom(code);
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading spinner
        if (success) {
          _codeController.clear();
          Navigator.of(context).pushNamed('/lobby');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to join room. Please check the code.'),
              backgroundColor: AppTheme.nopeRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomState = Provider.of<RoomState>(context);

    return Scaffold(
      body: Container(
        color: AppTheme.bgObsidian,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Custom Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cravit',
                          style: TextStyle(
                            fontFamily: Theme.of(context).textTheme.headlineLarge?.fontFamily,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Swipe with your squad',
                          style: TextStyle(color: AppTheme.textGray, fontSize: 13),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pushNamed('/profile');
                      },
                      borderRadius: BorderRadius.circular(22),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppTheme.cardObsidian,
                        child: ClipOval(
                          child: roomState.myAvatarUrl != null && roomState.myAvatarUrl!.startsWith('assets/')
                              ? Image.asset(
                                  roomState.myAvatarUrl!,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  roomState.myAvatarUrl ?? 'https://api.dicebear.com/7.x/bottts/svg?seed=you',
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: AppTheme.primaryCoral),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Create Room Glowing Button / Card
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryCoral.withOpacity(0.15 * _pulseController.value),
                            blurRadius: 16 + (8 * _pulseController.value),
                            spreadRadius: 2 * _pulseController.value,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: InkWell(
                    onTap: () => _handleCreateRoom(roomState),
                    borderRadius: BorderRadius.circular(24),
                    child: Ink(
                      height: 160,
                      decoration: BoxDecoration(
                        gradient: AppTheme.brandGradient,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Stack(
                        children: [
                          // Overlay details
                          Positioned(
                            right: -20,
                            bottom: -20,
                            child: Opacity(
                              opacity: 0.15,
                              child: Icon(Icons.restaurant_menu, size: 180, color: Colors.white),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(28.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    '🎉 Start Collaborative Swiping',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Create Room',
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Get a room code and invite friends to swipe together.',
                                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Join Room Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Join Room',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Enter your partner\'s 5-digit room code.',
                            style: TextStyle(color: AppTheme.textGray, fontSize: 13),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _codeController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 5,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. 54321',
                                    counterText: '',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    if (value.length != 5 || int.tryParse(value) == null) {
                                      return 'Must be 5 digits';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () => _handleJoinRoom(roomState),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.cardObsidianLight,
                                  side: BorderSide(color: AppTheme.borderGray),
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                ),
                                child: const Icon(Icons.arrow_forward, color: AppTheme.primaryCoral),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Squad Stats / Dashboard
                Text(
                  'Squad Stats',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                
                // Horizontal dashboard cards
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.25,
                  children: [
                    _buildStatCard(
                      context,
                      'Total Matches',
                      '42',
                      Icons.favorite,
                      AppTheme.secondaryPink,
                    ),
                    _buildStatCard(
                      context,
                      'Top Cuisine',
                      'Pizza 🍕',
                      Icons.restaurant,
                      AppTheme.primaryCoral,
                    ),
                    _buildStatCard(
                      context,
                      'Ties Resolved',
                      '15',
                      Icons.star,
                      AppTheme.starBlue,
                    ),
                    _buildStatCard(
                      context,
                      'Active Squads',
                      '3',
                      Icons.group,
                      Colors.purpleAccent,
                      onTap: () => Navigator.of(context).pushNamed('/squads'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return Card(
      color: AppTheme.cardObsidian,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color.withOpacity(0.85), size: 20),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(color: AppTheme.textGray, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
