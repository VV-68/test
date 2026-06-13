import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room_state.dart';
import '../theme/app_theme.dart';

class SwipeRestaurantsScreen extends StatefulWidget {
  const SwipeRestaurantsScreen({super.key});

  @override
  State<SwipeRestaurantsScreen> createState() => _SwipeRestaurantsScreenState();
}

class _SwipeRestaurantsScreenState extends State<SwipeRestaurantsScreen> with SingleTickerProviderStateMixin {
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
    if (state.matchedRestaurant != null) {
      state.removeListener(_stateListener);
      Navigator.of(context).pushReplacementNamed('/final-match');
    }
  }

  @override
  void dispose() {
    try {
      final state = Provider.of<RoomState>(context, listen: false);
      state.removeListener(_stateListener);
    } catch (_) {}
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_isAnimating) return;
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    setState(() {
      _cardOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details, List<Map<String, dynamic>> list, RoomState state) {
    if (_isAnimating) return;
    
    final threshold = MediaQuery.of(context).size.width * 0.35;
    if (_cardOffset.dx > threshold) {
      _swipeCard(true, list, state);
    } else if (_cardOffset.dx < -threshold) {
      _swipeCard(false, list, state);
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

  void _swipeCard(bool liked, List<Map<String, dynamic>> list, RoomState state) {
    if (_isAnimating) return;

    setState(() {
      _isAnimating = true;
      _isDragging = false;
    });

    final endOffset = liked ? const Offset(600, 100) : const Offset(-600, 100);
    final currentRestaurant = list[_currentIndex];

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
      state.swipeRestaurant(currentRestaurant, liked);

      setState(() {
        _currentIndex++;
        _cardOffset = Offset.zero;
        _isAnimating = false;
      });
      _animationController.reset();

      // Check match or navigation logic
      if (state.matchedRestaurant != null) {
        Navigator.of(context).pushReplacementNamed('/final-match');
      } else if (_currentIndex >= list.length) {
        // If swiped all options
        final allFinished = state.players.every((p) => p['isYou'] == true || (state.partnerProgress[p['name']] ?? 0) >= list.length);
        if (allFinished) {
          Navigator.of(context).pushReplacementNamed('/no-match');
        } else {
          Navigator.of(context).pushReplacementNamed('/waiting-swipes', arguments: 'restaurants');
        }
      }
    });
  }

  void _showDetailsBottomSheet(Map<String, dynamic> restaurant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final dishes = restaurant['popularDishes'] as List<String>? ?? [];
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.cardObsidian,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(28.0),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppTheme.borderGray,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          restaurant['name'] ?? '',
                          style: TextStyle(
                            color: AppTheme.textWhite,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryCoral.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          restaurant['price'] ?? 'Below ₹500',
                          style: const TextStyle(color: AppTheme.primaryCoral, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${restaurant['rating'] ?? 4.0}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${restaurant['reviewsCount'] ?? 100} reviews)',
                        style: TextStyle(color: AppTheme.textGray, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(color: AppTheme.borderGray),
                  const SizedBox(height: 16),
                  const Text(
                    'About',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    restaurant['desc'] ?? '',
                    style: TextStyle(color: AppTheme.textGray, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Popular Dishes',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ...dishes.map((dish) => Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: AppTheme.primaryCoral, size: 18),
                            const SizedBox(width: 8),
                            Text(dish, style: TextStyle(color: AppTheme.textWhite)),
                          ],
                        ),
                      )),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<RoomState>(context);
    final matchedCuisine = state.matchedCuisine ?? 'Pizza';
    final restaurants = state.restaurantsByCuisine[matchedCuisine] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Stage 2: $matchedCuisine'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppTheme.textWhite),
          onPressed: () {
            state.resetSwipingState();
            Navigator.of(context).pop();
          },
        ),
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
                child: _buildProgressBar('You', _currentIndex, restaurants.length, AppTheme.primaryCoral),
              ),

              const SizedBox(height: 20),
              
              // Card deck stack
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Confine card height to the available height with a small buffer for the background stack preview translation
                      final cardHeight = constraints.maxHeight - 20.0;
                      return Center(
                        child: restaurants.isEmpty
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('🍽️', style: TextStyle(fontSize: 64)),
                                  SizedBox(height: 16),
                                  Text(
                                    'No restaurants found',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Try matching on a different cuisine.',
                                    style: TextStyle(color: AppTheme.textGray, fontSize: 14),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )
                            : (_currentIndex < restaurants.length
                                ? Stack(
                                    alignment: Alignment.center,
                                    children: List.generate(
                                      restaurants.length,
                                      (index) {
                                        if (index < _currentIndex) return const SizedBox.shrink();
                                        if (index == _currentIndex) {
                                          return _buildActiveRestaurantCard(restaurants, state, cardHeight);
                                        }
                                        final depthIndex = index - _currentIndex;
                                        if (depthIndex > 2) return const SizedBox.shrink();
                                        return Transform.translate(
                                          offset: Offset(0.0, depthIndex * 8.0),
                                          child: Transform.scale(
                                            scale: 1.0 - (depthIndex * 0.04),
                                            child: _buildStaticRestaurantCard(restaurants[index], cardHeight),
                                          ),
                                        );
                                      },
                                    ).reversed.toList(),
                                  )
                                : const Center(
                                    child: CircularProgressIndicator(color: AppTheme.primaryCoral),
                                  )),
                      );
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Custom Bottom Buttons or Back to Home
              if (restaurants.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryCoral.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        state.resetSwipingState();
                        Navigator.of(context).popUntil(ModalRoute.withName('/home'));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryCoral,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: const Text(
                        'Back to Home',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                )
              else if (_currentIndex < restaurants.length)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Nope Button
                      _buildRoundButton(
                        icon: Icons.close,
                        color: AppTheme.nopeRed,
                        iconSize: 28,
                        size: 64,
                        onTap: () => _swipeCard(false, restaurants, state),
                      ),
                      const SizedBox(width: 40),
                      // Like Button
                      _buildRoundButton(
                        icon: Icons.favorite,
                        color: AppTheme.likeGreen,
                        iconSize: 28,
                        size: 64,
                        onTap: () => _swipeCard(true, restaurants, state),
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
    final pct = total > 0 ? val / total : 0.0;
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

  Widget _buildActiveRestaurantCard(List<Map<String, dynamic>> list, RoomState state, double cardHeight) {
    final restaurant = list[_currentIndex];
    final offset = _isDragging
        ? _cardOffset
        : (_isAnimating ? _swipeAnimation.value : Offset.zero);
    final angle = (offset.dx / 300) * 0.25;

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: (details) => _onPanEnd(details, list, state),
      onPanCancel: _onPanCancel,
      onTap: () => _showDetailsBottomSheet(restaurant),
      child: Transform.translate(
        offset: offset,
        child: Transform.rotate(
          angle: angle,
          child: Stack(
            children: [
              _buildStaticRestaurantCard(restaurant, cardHeight),
              
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

  Widget _buildStaticRestaurantCard(Map<String, dynamic> restaurant, double cardHeight) {
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
            Image.network(
              restaurant['image'],
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppTheme.cardObsidianLight,
                child: Center(
                  child: Icon(Icons.restaurant, size: 64, color: AppTheme.textGray),
                ),
              ),
            ),
            
            // Rich Gradient Vignette
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.90)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            
            // Bottom Info Column
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryCoral,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${restaurant['rating']} ⭐',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        restaurant['deliveryTime'] ?? '25 mins',
                        style: TextStyle(color: AppTheme.textWhite, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    restaurant['name'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        restaurant['price'] ?? 'Below ₹500',
                        style: const TextStyle(color: AppTheme.primaryCoral, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      Text('•', style: TextStyle(color: AppTheme.textGray)),
                      const SizedBox(width: 8),
                      Text(
                        restaurant['distance'] ?? '1.0 km',
                        style: TextStyle(color: AppTheme.textGray, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.keyboard_arrow_up, color: AppTheme.textGray, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Tap card for details',
                        style: TextStyle(color: AppTheme.textGray, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
