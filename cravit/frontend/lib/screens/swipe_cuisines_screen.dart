import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room_state.dart';
import '../theme/app_theme.dart';

class SwipeCuisinesScreen extends StatefulWidget {
  const SwipeCuisinesScreen({super.key});

  @override
  State<SwipeCuisinesScreen> createState() => _SwipeCuisinesScreenState();
}

class _SwipeCuisinesScreenState extends State<SwipeCuisinesScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Offset _cardOffset = Offset.zero;
  bool _isDragging = false;
  bool _isAnimating = false;
  late AnimationController _animationController;
  late Animation<Offset> _swipeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _swipeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_animationController);

    // Listen to room state matches
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<RoomState>(context, listen: false);
      state.addListener(_stateListener);
    });
  }

  void _stateListener() {
    if (!mounted) return;
    final state = Provider.of<RoomState>(context, listen: false);
    if (state.matchedCuisine != null) {
      state.removeListener(_stateListener);
      Navigator.of(context).pushReplacementNamed('/match-transition');
    }
  }

  @override
  void dispose() {
    // Safely remove listener
    try {
      final state = Provider.of<RoomState>(context, listen: false);
      state.removeListener(_stateListener);
    } catch (_) {}
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    final state = Provider.of<RoomState>(context, listen: false);
    if (_currentIndex >= state.cuisines.length || _isAnimating) return;
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final state = Provider.of<RoomState>(context, listen: false);
    if (_currentIndex >= state.cuisines.length || _isAnimating) return;
    setState(() {
      _cardOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details, RoomState state) {
    if (_currentIndex >= state.cuisines.length || _isAnimating) return;
    
    final threshold = MediaQuery.of(context).size.width * 0.35;
    if (_cardOffset.dx > threshold) {
      _swipeCard(true, state); // Swipe Right (Like)
    } else if (_cardOffset.dx < -threshold) {
      _swipeCard(false, state); // Swipe Left (Nope)
    } else {
      _snapBack();
    }
  }

  void _onPanCancel() {
    _snapBack();
  }

  void _snapBack() {
    if (_isAnimating) return;
    setState(() {
      _isAnimating = true;
      _isDragging = false;
    });

    _swipeAnimation = Tween<Offset>(
      begin: _cardOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.duration = const Duration(milliseconds: 350);
    _animationController.reset();
    _animationController.forward().then((_) {
      setState(() {
        _cardOffset = Offset.zero;
        _isAnimating = false;
      });
      _animationController.reset();
    });
  }

  void _swipeCard(bool liked, RoomState state) {
    if (_isAnimating) return;
    
    setState(() {
      _isAnimating = true;
      _isDragging = false;
    });

    final endOffset = liked ? const Offset(600, 100) : const Offset(-600, 100);
    final currentCuisine = state.cuisines[_currentIndex]['name'] as String;

    _swipeAnimation = Tween<Offset>(
      begin: _cardOffset,
      end: endOffset,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    ));

    _animationController.duration = const Duration(milliseconds: 250);
    _animationController.reset();
    _animationController.forward().then((_) {
      state.swipeCuisine(currentCuisine, liked);
      
      setState(() {
        _currentIndex++;
        _cardOffset = Offset.zero;
        _isAnimating = false;
      });
      _animationController.reset();

      // Check navigation logic
      if (state.matchedCuisine != null) {
        Navigator.of(context).pushReplacementNamed('/match-transition');
      } else if (_currentIndex >= state.cuisines.length) {
        // If swiped everything and no match yet
        final allFinished = state.players.every((p) => p['isYou'] == true || (state.partnerProgress[p['name']] ?? 0) >= state.cuisines.length);
        if (allFinished) {
          Navigator.of(context).pushReplacementNamed('/no-match');
        } else {
          Navigator.of(context).pushReplacementNamed('/waiting-swipes', arguments: 'cuisines');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<RoomState>(context);
    final totalCuisines = state.cuisines.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stage 1: Cuisines'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppTheme.textWhite),
          onPressed: () {
            state.resetSwipingState();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: AppTheme.textGray),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Swipe right to Like, left to Nope. Find a common choice!'),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: AppTheme.bgObsidian,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Bars Panel - Only show 'You' progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: _buildProgressBar('You', _currentIndex, totalCuisines, AppTheme.primaryCoral),
              ),
              
              const SizedBox(height: 20),

              // Card Stack
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Confine card height to the available height with a small buffer for the background stack preview translation
                      final cardHeight = constraints.maxHeight - 20.0;
                      return Center(
                        child: _currentIndex < totalCuisines
                            ? Stack(
                                alignment: Alignment.center,
                                children: List.generate(
                                  totalCuisines,
                                  (index) {
                                    if (index < _currentIndex) return const SizedBox.shrink();
                                    if (index == _currentIndex) {
                                      // Active swipeable top card
                                      return _buildActiveCard(state, cardHeight);
                                    }
                                    // Static background cards for stack preview depth
                                    final depthIndex = index - _currentIndex;
                                    if (depthIndex > 2) return const SizedBox.shrink(); // Show up to 3 cards
                                    return Transform.translate(
                                      offset: Offset(0.0, depthIndex * 8.0),
                                      child: Transform.scale(
                                        scale: 1.0 - (depthIndex * 0.04),
                                        child: _buildStaticCard(state.cuisines[index], cardHeight),
                                      ),
                                    );
                                  },
                                ).reversed.toList(),
                              )
                            : _buildEmptyState(),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Control Buttons Bar
              if (_currentIndex < totalCuisines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Veto / Nope Button (Standard Close icon)
                      _buildRoundButton(
                        icon: Icons.close,
                        color: AppTheme.nopeRed,
                        iconSize: 28,
                        size: 64,
                        onTap: () => _swipeCard(false, state),
                      ),
                      const SizedBox(width: 40),
                      // Like Button
                      _buildRoundButton(
                        icon: Icons.favorite,
                        color: AppTheme.likeGreen,
                        iconSize: 28,
                        size: 64,
                        onTap: () => _swipeCard(true, state),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, int val, int total, Color color) {
    final pct = val / total;
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: TextStyle(color: AppTheme.textWhite, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppTheme.borderGray,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$val/$total',
          style: TextStyle(color: AppTheme.textGray, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildActiveCard(RoomState state, double cardHeight) {
    final cuisine = state.cuisines[_currentIndex];
    final offset = _isDragging
        ? _cardOffset
        : (_isAnimating ? _swipeAnimation.value : Offset.zero);
    final angle = (offset.dx / 300) * 0.25; // Dynamic rotation angle

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: (details) => _onPanEnd(details, state),
      onPanCancel: _onPanCancel,
      child: Transform.translate(
        offset: offset,
        child: Transform.rotate(
          angle: angle,
          child: Stack(
            children: [
              _buildStaticCard(cuisine, cardHeight),
              
              // LIKE Overlay Stamp
              if (offset.dx > 40)
                Positioned(
                  top: 40,
                  left: 30,
                  child: Transform.rotate(
                    angle: -0.2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.likeGreen, width: 3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'LIKE',
                        style: TextStyle(color: AppTheme.likeGreen, fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),

              // NOPE Overlay Stamp
              if (offset.dx < -40)
                Positioned(
                  top: 40,
                  right: 30,
                  child: Transform.rotate(
                    angle: 0.2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.nopeRed, width: 3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'NOPE',
                        style: TextStyle(color: AppTheme.nopeRed, fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaticCard(Map<String, dynamic> cuisine, double cardHeight) {
    return Container(
      width: double.infinity,
      height: cardHeight,
      decoration: BoxDecoration(
        color: AppTheme.cardObsidian,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderGray, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Cuisine image backdrop
            Image.asset(
              cuisine['image'] ?? 'assets/images/burger_cuisine.png',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
            // Dark gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.92)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Content Card center
            Positioned(
              bottom: 30,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cuisine['name'] ?? '',
                    style: TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cuisine['tagline'] ?? '',
                    style: TextStyle(
                      color: AppTheme.textGray,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.primaryCoral),
    );
  }

  Widget _buildRoundButton({
    required IconData icon,
    required Color color,
    required double iconSize,
    required double size,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.cardObsidian,
          border: Border.all(color: AppTheme.borderGray, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            color: color,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}
