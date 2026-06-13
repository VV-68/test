import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room_state.dart';
import '../theme/app_theme.dart';

class NoMatchScreen extends StatefulWidget {
  const NoMatchScreen({super.key});

  @override
  State<NoMatchScreen> createState() => _NoMatchScreenState();
}

class _NoMatchScreenState extends State<NoMatchScreen> with SingleTickerProviderStateMixin {
  late AnimationController _coinController;
  late Animation<double> _coinAnimation;
  bool _isFlipped = false;
  String _dictatorWinner = '';

  @override
  void initState() {
    super.initState();
    _coinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _coinAnimation = Tween<double>(begin: 0, end: 10 * pi).animate(
      CurvedAnimation(parent: _coinController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _coinController.dispose();
    super.dispose();
  }

  void _flipCoin() {
    if (_coinController.isAnimating) return;
    
    setState(() {
      _isFlipped = true;
      _dictatorWinner = '';
    });

    _coinController.reset();
    _coinController.forward().then((_) {
      final rand = Random();
      setState(() {
        _dictatorWinner = rand.nextBool() ? 'You' : 'Sarah';
      });
    });
  }

  void _showDictatorDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardObsidian,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: AppTheme.borderGray),
              ),
              title: const Center(
                child: Text(
                  '👑 The Dictator',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Flip a coin. The winner gets full command to pick the restaurant!',
                    style: TextStyle(color: AppTheme.textGray, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  
                  // Interactive Coin
                  GestureDetector(
                    onTap: () {
                      _flipCoin();
                      // Update dialog state to trigger animation rebuilds
                      setDialogState(() {});
                      _coinController.addListener(() {
                        setDialogState(() {});
                      });
                    },
                    child: AnimatedBuilder(
                      animation: _coinAnimation,
                      builder: (context, child) {
                        final angle = _coinAnimation.value;
                        return Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.002) // Perspective
                            ..rotateX(angle),
                          alignment: Alignment.center,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppTheme.brandGradient,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryCoral.withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                '🪙',
                                style: TextStyle(fontSize: 48),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  if (_coinController.isAnimating)
                    const Text('Flipping... 🪙', style: TextStyle(fontWeight: FontWeight.bold))
                  else if (_dictatorWinner.isNotEmpty)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.likeGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Winner: $_dictatorWinner! 👑',
                            style: const TextStyle(
                              color: AppTheme.likeGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Select the final choice:',
                          style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        ...(() {
                          final state = Provider.of<RoomState>(context, listen: false);
                          final matchedCuisine = state.matchedCuisine ?? 'Pizza';
                          final restaurants = state.restaurantsByCuisine[matchedCuisine] ?? [];
                          return restaurants.map((r) {
                            final name = r['name'] as String;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.cardObsidianLight,
                                  foregroundColor: AppTheme.primaryCoral,
                                  side: BorderSide(color: AppTheme.borderGray),
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  minimumSize: const Size(double.infinity, 44),
                                ),
                                onPressed: () {
                                  state.setMatchedRestaurantByName(name);
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pushReplacementNamed('/final-match');
                                },
                                child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            );
                          });
                        })(),
                      ],
                    )
                  else
                    const Text(
                      'Tap coin to flip!',
                      style: TextStyle(color: AppTheme.primaryCoral, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              actions: [
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Close'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAICompromiseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardObsidian,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppTheme.borderGray),
        ),
        title: const Center(
          child: Text(
            '🤖 AI Compromise',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Analyzing preferences... Based on your swiping histories, here is the ultimate compromise recommendation:',
              style: TextStyle(color: AppTheme.textGray, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // Recommedation Card
            Card(
              color: AppTheme.cardObsidianLight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('🍣', style: TextStyle(fontSize: 44)),
                    const SizedBox(height: 8),
                    const Text(
                      'Sakura Sushi & Grill',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        const Text('4.6', style: TextStyle(color: Colors.white, fontSize: 12)),
                        const SizedBox(width: 8),
                        Text('• 1.8 km', style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Since you swiped right on Pizza (carb-heavy) and Sarah liked Salads (healthy), AI suggests Sushi — fresh, high-protein, and satisfying!',
                      style: TextStyle(color: AppTheme.textGray, fontSize: 11, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                final state = Provider.of<RoomState>(context, listen: false);
                state.setMatchedRestaurantByName("Tony's Sourdough Pizzeria");
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/final-match');
              },
              child: const Text('Go with AI!'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Finished'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        color: AppTheme.bgObsidian,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Sad food emoji header
                Center(
                  child: Column(
                    children: [
                      Text('😢🍕', style: TextStyle(fontSize: 64)),
                      SizedBox(height: 20),
                      Text(
                        'No Match Found!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your squad swiped on everything, but could not agree on a single choice.',
                        style: TextStyle(color: AppTheme.textGray, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),

                // Fallback choices stack
                Text(
                  'CHOOSE A FALLBACK GAME',
                  style: TextStyle(
                    color: AppTheme.textGray,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),

                // Button 1: Merge & Spin (Roulette)
                _buildFallbackCard(
                  context,
                  title: 'Merge & Spin',
                  desc: 'Combines all top liked choices of your squad and spins a roulette wheel.',
                  icon: Icons.refresh,
                  color: AppTheme.primaryCoral,
                  onTap: () {
                    Navigator.of(context).pushNamed('/roulette');
                  },
                ),
                const SizedBox(height: 14),

                // Button 2: The Dictator (Coin Flip)
                _buildFallbackCard(
                  context,
                  title: 'The Dictator',
                  desc: 'A simple coin flip. The winner gets absolute command to choose the meal.',
                  icon: Icons.gavel,
                  color: AppTheme.secondaryPink,
                  onTap: _showDictatorDialog,
                ),
                const SizedBox(height: 14),

                // Button 3: AI Compromise
                _buildFallbackCard(
                  context,
                  title: 'AI Compromise',
                  desc: 'Let our algorithm analyze swiping histories to recommend a middleground choice.',
                  icon: Icons.psychology,
                  color: AppTheme.starBlue,
                  onTap: _showAICompromiseDialog,
                ),

                const SizedBox(height: 24),

                // Return home
                TextButton(
                  onPressed: () {
                    Navigator.of(context).popUntil(ModalRoute.withName('/home'));
                  },
                  child: Text(
                    'Back to Home Screen',
                    style: TextStyle(color: AppTheme.textGray),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackCard(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardObsidian,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderGray, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.15),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(
                      color: AppTheme.textGray,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: AppTheme.textGray, size: 14),
          ],
        ),
      ),
    );
  }
}
