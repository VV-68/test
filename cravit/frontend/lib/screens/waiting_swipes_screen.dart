import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room_state.dart';
import '../theme/app_theme.dart';

class WaitingSwipesScreen extends StatefulWidget {
  const WaitingSwipesScreen({super.key});

  @override
  State<WaitingSwipesScreen> createState() => _WaitingSwipesScreenState();
}

class _WaitingSwipesScreenState extends State<WaitingSwipesScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Set up state listener to transition automatically when a match is found or finished
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RoomState>(context, listen: false).addListener(_stateListener);
    });
  }

  void _stateListener() {
    if (!mounted) return;
    final state = Provider.of<RoomState>(context, listen: false);
    final stage = ModalRoute.of(context)!.settings.arguments as String? ?? 'cuisines';
    
    if (stage == 'cuisines') {
      if (state.matchedCuisine != null) {
        state.removeListener(_stateListener);
        Navigator.of(context).pushReplacementNamed('/match-transition');
      } else {
        // Check if all finished
        final totalCount = state.cuisines.length;
        final allFinished = state.players.every((p) => p['isYou'] == true || (state.partnerProgress[p['name']] ?? 0) >= totalCount);
        if (allFinished) {
          state.removeListener(_stateListener);
          Navigator.of(context).pushReplacementNamed('/no-match');
        }
      }
    } else {
      // restaurants
      if (state.matchedRestaurant != null) {
        state.removeListener(_stateListener);
        Navigator.of(context).pushReplacementNamed('/final-match');
      } else {
        // Check if all finished
        final matchedCuisineName = state.matchedCuisine ?? 'Pizza';
        final list = state.restaurantsByCuisine[matchedCuisineName] ?? [];
        final totalCount = list.length;
        final allFinished = state.players.every((p) => p['isYou'] == true || (state.partnerProgress[p['name']] ?? 0) >= totalCount);
        if (allFinished) {
          state.removeListener(_stateListener);
          Navigator.of(context).pushReplacementNamed('/no-match');
        }
      }
    }
  }

  @override
  void dispose() {
    try {
      Provider.of<RoomState>(context, listen: false).removeListener(_stateListener);
    } catch (_) {}
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<RoomState>(context);
    final stage = ModalRoute.of(context)!.settings.arguments as String? ?? 'cuisines';
    
    final matchedCuisineName = state.matchedCuisine ?? 'Pizza';
    final totalCount = stage == 'cuisines'
        ? state.cuisines.length
        : (state.restaurantsByCuisine[matchedCuisineName] ?? []).length;

    // Filter list to only show other squad members
    final partners = state.players.where((p) => p['isYou'] != true).toList();

    return Scaffold(
      body: Container(
        color: AppTheme.bgObsidian,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Pulsing Loader / Spinner in center
                Center(
                  child: ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.cardObsidian,
                        border: Border.all(color: AppTheme.primaryCoral, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryCoral.withOpacity(0.2),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.restaurant,
                          color: AppTheme.primaryCoral,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 48),

                // Title & Subtitle
                Text(
                  'Waiting for your Squad...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You swiped all options. We will notify you once squad matches are computed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textGray,
                  ),
                ),
                
                const SizedBox(height: 40),

                // Squad Swiping Live Progress Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Squad Swiping Progress',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryPink.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: AppTheme.secondaryPink,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Glassmorphic Progress List of Partners
                Expanded(
                  child: partners.isEmpty
                      ? Center(
                          child: Text(
                            'No partners in this session.',
                            style: TextStyle(color: AppTheme.textGray),
                          ),
                        )
                      : ListView.separated(
                          itemCount: partners.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final partner = partners[index];
                            final name = partner['name'] as String;
                            final currentProgress = state.partnerProgress[name] ?? 0;
                            final pct = totalCount > 0 ? currentProgress / totalCount : 0.0;
                            final isDone = currentProgress >= totalCount;

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppTheme.cardObsidian,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.borderGray),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: AppTheme.cardObsidianLight,
                                        child: Image.network(
                                          partner['avatarUrl'] ?? '',
                                          width: 24,
                                          height: 24,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Icon(Icons.person, color: AppTheme.textGray, size: 16),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: TextStyle(
                                            color: AppTheme.textWhite,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      isDone
                                          ? const Row(
                                              children: [
                                                Icon(Icons.check_circle, color: AppTheme.likeGreen, size: 16),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Done',
                                                  style: TextStyle(
                                                    color: AppTheme.likeGreen,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Row(
                                              children: [
                                                const SizedBox(
                                                  width: 10,
                                                  height: 10,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 1.5,
                                                    color: AppTheme.primaryCoral,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '$currentProgress/$totalCount',
                                                  style: const TextStyle(
                                                    color: AppTheme.primaryCoral,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: pct,
                                      minHeight: 6,
                                      backgroundColor: AppTheme.borderGray,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isDone ? AppTheme.likeGreen : AppTheme.secondaryPink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                const SizedBox(height: 16),
                
                // Cancel button to leave session safely
                TextButton(
                  onPressed: () {
                    state.resetSwipingState();
                    Navigator.of(context).popUntil(ModalRoute.withName('/home'));
                  },
                  child: Text(
                    'Cancel and Leave Session',
                    style: TextStyle(color: AppTheme.textGray, fontSize: 13, decoration: TextDecoration.underline),
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
