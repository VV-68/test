import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class RoomState extends ChangeNotifier {
  // Theme settings state
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleThemeMode(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    AppTheme.setThemeMode(isDark);
    notifyListeners();
  }

  // User profile variables
  String? _myDisplayName;
  String? _myAvatarUrl;
  String? _myUsername;

  String? get myDisplayName => _myDisplayName;
  String? get myAvatarUrl => _myAvatarUrl;
  String? get myUsername => _myUsername;

  Future<void> loadUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (data != null) {
        _myDisplayName = data['display_name'];
        _myAvatarUrl = data['avatar_url'];
        _myUsername = data['username'];
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> updateUserProfile(String displayName, String avatarUrl) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client.from('users').update({
        'display_name': displayName,
        'avatar_url': avatarUrl,
      }).eq('id', user.id);
      
      _myDisplayName = displayName;
      _myAvatarUrl = avatarUrl;
      notifyListeners();
      
      if (_roomId != null) {
        _refreshRoomDetails();
      }
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Supabase Realtime Channels
  RealtimeChannel? _membersChannel;
  RealtimeChannel? _sessionChannel;
  RealtimeChannel? _matchesChannel;

  // Room state variables
  String? _roomId;
  String? _roomCode;
  String? _sessionId;
  List<Map<String, dynamic>> _players = [];
  bool _isHost = false;

  // Filter preferences state variables (synced to backend sessions table)
  double _distanceRadius = 5.0; // in km
  int _budgetIndex = 1; // Default to 'Below ₹250'
  List<String> _selectedDietaryTags = [];
  int _timerMinutes = 5;
  int _maxParticipants = 2; // Default limit

  // Swiping State Variables
  List<String> _myLikedCuisines = [];
  String? _matchedCuisine;
  
  List<Map<String, dynamic>> _myLikedRestaurants = [];
  Map<String, dynamic>? _matchedRestaurant;

  // Progress for multiplayer UI
  final Map<String, int> _partnerProgress = {};

  // Getters
  String? get roomCode => _roomCode;
  String? get roomId => _roomId;
  String? get sessionId => _sessionId;
  List<Map<String, dynamic>> get players => _players;
  bool get isHost => _isHost;
  double get distanceRadius => _distanceRadius;
  int get budgetIndex => _budgetIndex;
  List<String> get selectedDietaryTags => _selectedDietaryTags;
  int get timerMinutes => _timerMinutes;
  int get maxParticipants => _maxParticipants;

  List<String> get myLikedCuisines => _myLikedCuisines;
  String? get matchedCuisine => _matchedCuisine;
  List<Map<String, dynamic>> get myLikedRestaurants => _myLikedRestaurants;
  Map<String, dynamic>? get matchedRestaurant => _matchedRestaurant;
  Map<String, int> get partnerProgress => _partnerProgress;

  String get currentPhase {
    if (_roomId == null) return 'LOBBY';
    // If we have an active session, retrieve phase
    return _currentPhase;
  }
  String _currentPhase = 'LOBBY';

  // Mock databases for UI selections
  final List<String> budgetOptions = [
    'Below ₹100',
    'Below ₹250',
    'Below ₹500',
    'Below ₹1000',
    'Below ₹2000'
  ];
  final List<String> dietaryOptions = [
    'Vegan',
    'Vegetarian',
    'Gluten-Free',
    'Halal',
    'Keto',
    'Dairy-Free',
    'Nut-Free',
    'Kosher'
  ];

  final List<Map<String, dynamic>> cuisines = [
    {'name': 'Pizza', 'image': 'assets/images/pizza_cuisine.png', 'tagline': 'Hot, cheesy, and doughy slices.'},
    {'name': 'Burgers', 'image': 'assets/images/burger_cuisine.png', 'tagline': 'Sizzling patties and melting cheese.'},
    {'name': 'Sushi', 'image': 'assets/images/sushi_cuisine.png', 'tagline': 'Freshly prepared rolls & sashimi.'},
    {'name': 'Pasta', 'image': 'assets/images/pasta_cuisine.png', 'tagline': 'Saucy and rich classic Italian noodles.'},
    {'name': 'Tacos', 'image': 'assets/images/taco_cuisine.png', 'tagline': 'Crunchy tortillas filled with spices.'},
    {'name': 'Salads', 'image': 'assets/images/salad_cuisine.png', 'tagline': 'Fresh green bowls and healthy dressings.'},
  ];

  List<Map<String, dynamic>> _fetchedRestaurants = [];
  Map<String, List<Map<String, dynamic>>> get restaurantsByCuisine => {
    _matchedCuisine ?? 'Pizza': _fetchedRestaurants,
  };

  // Squads dashboard stub
  final List<Map<String, dynamic>> squads = [
    {
      'name': 'Friday Night Boys',
      'members': 4,
      'matches': 18,
      'topCuisine': 'Pizza 🍕',
      'avatarColor': 0xFFFF6B4A,
    },
    {
      'name': 'Office Lunch Squad',
      'members': 6,
      'matches': 32,
      'topCuisine': 'Burgers 🍔',
      'avatarColor': 0xFFFF4B72,
    },
    {
      'name': 'Brunch & Babble',
      'members': 3,
      'matches': 9,
      'topCuisine': 'Salads 🥗',
      'avatarColor': 0xFF4FA7FF,
    },
  ];

  // Actions
  Future<void> createRoom() async {
    resetSwipingState();
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'room_manager',
        body: {'action': 'create_room'}
      );
      final data = response.data;
      if (data != null && data['room'] != null) {
        final room = data['room'];
        _roomId = room['id'];
        _roomCode = room['room_code'];
        _isHost = true;
        
        final user = Supabase.instance.client.auth.currentUser;
        _players = [
          {
            'user_id': user?.id,
            'name': '${_myDisplayName ?? 'You'} (Host)',
            'avatarUrl': _myAvatarUrl ?? 'https://api.dicebear.com/7.x/bottts/svg?seed=${user?.id ?? 'host'}',
            'isReady': true,
            'isYou': true,
          }
        ];
        
        _setupRealtimeSubscriptions();
        await _syncSettingsToBackend();
        notifyListeners();
      }
    } catch (e) {
      print('Failed to create room: $e');
    }
  }

  Future<bool> joinRoom(String code) async {
    resetSwipingState();
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'room_manager',
        body: {
          'action': 'join_room',
          'payload': {'room_code': code}
        }
      );
      final data = response.data;
      if (data != null && data['room'] != null) {
        final room = data['room'];
        _roomId = room['id'];
        _roomCode = room['room_code'];
        _isHost = false;
        
        _setupRealtimeSubscriptions();
        await _refreshRoomDetails();
        return true;
      }
    } catch (e) {
      print('Failed to join room: $e');
    }
    return false;
  }

  Future<void> leaveRoom() async {
    if (_roomId != null) {
      try {
        await Supabase.instance.client.functions.invoke(
          'room_manager',
          body: {
            'action': 'leave_room',
            'payload': {'room_id': _roomId}
          }
        );
      } catch (e) {
        print('Error leaving room in backend: $e');
      }
    }
    _cancelRealtimeSubscriptions();
    _roomId = null;
    _roomCode = null;
    _sessionId = null;
    _players = [];
    _isHost = false;
    resetSwipingState();
    notifyListeners();
  }

  void resetSwipingState() {
    _myLikedCuisines = [];
    _matchedCuisine = null;
    _myLikedRestaurants = [];
    _matchedRestaurant = null;
    _partnerProgress.clear();
    _fetchedRestaurants = [];
    _currentPhase = 'LOBBY';
  }

  // Filter setters (Host syncs to session manager)
  void setDistance(double value) {
    _distanceRadius = value;
    notifyListeners();
    _syncSettingsToBackend();
  }

  void setBudget(int index) {
    if (index >= 0 && index < budgetOptions.length) {
      _budgetIndex = index;
      notifyListeners();
      _syncSettingsToBackend();
    }
  }

  void toggleDietaryTag(String tag) {
    if (_selectedDietaryTags.contains(tag)) {
      _selectedDietaryTags.remove(tag);
    } else {
      _selectedDietaryTags.add(tag);
    }
    notifyListeners();
    _syncSettingsToBackend();
  }

  void setTimerMinutes(int minutes) {
    _timerMinutes = minutes;
    notifyListeners();
    _syncSettingsToBackend();
  }

  void setMaxParticipants(int val) {
    if (val >= 1) {
      _maxParticipants = val;
      notifyListeners();
      _syncSettingsToBackend();
    }
  }

  // Swipe Actions: Calls backend
  Future<void> swipeCuisine(String cuisineName, bool liked) async {
    if (_sessionId == null) return;
    if (liked) {
      _myLikedCuisines.add(cuisineName);
    }
    notifyListeners();

    try {
      await Supabase.instance.client.functions.invoke(
        'swipe_handler',
        body: {
          'action': 'cuisine_swipe',
          'payload': {
            'session_id': _sessionId,
            'target_id': cuisineName,
            'swipe_value': liked ? 'LIKE' : 'DISLIKE',
          }
        }
      );
    } catch (e) {
      print('Failed to register cuisine swipe: $e');
    }
  }

  Future<void> swipeRestaurant(Map<String, dynamic> restaurant, bool liked) async {
    if (_sessionId == null) return;
    if (liked) {
      _myLikedRestaurants.add(restaurant);
    }
    notifyListeners();

    try {
      await Supabase.instance.client.functions.invoke(
        'swipe_handler',
        body: {
          'action': 'restaurant_swipe',
          'payload': {
            'session_id': _sessionId,
            'target_id': restaurant['id'],
            'swipe_value': liked ? 'LIKE' : 'DISLIKE',
            'restaurant_name': restaurant['name'],
          }
        }
      );
    } catch (e) {
      print('Failed to register restaurant swipe: $e');
    }
  }

  // Triggered when roulette or dictatorial coin flip decides the winner
  void setMatchedRestaurantByName(String name) {
    for (final r in _fetchedRestaurants) {
      if (r['name'] == name) {
        _matchedRestaurant = r;
        notifyListeners();
        return;
      }
    }
  }

  // Ready state toggle for non-hosts
  Future<void> toggleReady(bool isReady) async {
    if (_roomId == null) return;
    try {
      await Supabase.instance.client.functions.invoke(
        'session_manager',
        body: {
          'action': 'set_ready',
          'payload': {
            'room_id': _roomId,
            'is_ready': isReady,
          }
        }
      );
    } catch (e) {
      print('Failed to set readiness state: $e');
    }
  }

  // Start Session (Host-only trigger)
  Future<void> startSession() async {
    if (_roomId == null) return;
    try {
      await Supabase.instance.client.functions.invoke(
        'session_manager',
        body: {
          'action': 'start_session',
          'payload': {'room_id': _roomId}
        }
      );
    } catch (e) {
      print('Failed to start session: $e');
    }
  }

  // Fetch real restaurants using provider edge function
  Future<void> fetchRestaurantsForCuisine(String cuisine) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'restaurant_provider',
        body: {
          'action': 'get_restaurants',
          'payload': {
            'cuisine': cuisine,
            'latitude': 12.9716, // Default fallback location (Bangalore)
            'longitude': 77.5946,
          }
        }
      );
      
      final data = response.data;
      if (data != null && data['restaurants'] != null) {
        final List<dynamic> rawList = data['restaurants'];
        _fetchedRestaurants = rawList.map((item) {
          final details = item['details'] ?? {};
          final rating = details['rating'] ?? 4.2;
          final reviewsCount = details['reviews'] ?? 150;
          final distance = item['distance'] != null ? '${item['distance']} km' : '1.2 km';
          final address = item['address'] ?? 'Nearby address';
          
          return {
            'id': item['id'] ?? 'res_${Random().nextInt(10000)}',
            'name': item['name'] ?? 'Local Bistro',
            'image': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=500',
            'rating': rating,
            'reviewsCount': reviewsCount,
            'distance': distance,
            'deliveryTime': '20-30 mins',
            'price': 'Below ₹500',
            'desc': address,
            'popularDishes': ['Special Combo', 'Chef Select'],
          };
        }).toList();
      }
      notifyListeners();
    } catch (e) {
      print('Failed to load restaurants: $e');
      _fetchedRestaurants = [];
      notifyListeners();
    }
  }

  // Realtime Integration helpers
  void _setupRealtimeSubscriptions() {
    _cancelRealtimeSubscriptions();
    final client = Supabase.instance.client;

    if (_roomId != null) {
      _membersChannel = client.channel('public:room_members:room_id=eq.$_roomId')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'room_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: _roomId,
          ),
          callback: (payload) {
            _refreshRoomDetails();
          },
        )
        ..subscribe();

      _sessionChannel = client.channel('public:sessions:room_id=eq.$_roomId')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: _roomId,
          ),
          callback: (payload) {
            final data = payload.newRecord;
            if (data.isNotEmpty) {
              _updateSessionFromDb(data);
            }
          },
        )
        ..subscribe();
    }
  }

  void _setupMatchesChannel(String sessionId) {
    if (_matchesChannel != null) {
      Supabase.instance.client.removeChannel(_matchesChannel!);
    }

    _matchesChannel = Supabase.instance.client.channel('public:matches:session_id=eq.$sessionId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'matches',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'session_id',
          value: sessionId,
        ),
        callback: (payload) {
          final data = payload.newRecord;
          if (data.isNotEmpty) {
            _onMatchFound(data);
          }
        },
      )
      ..subscribe();
  }

  void _cancelRealtimeSubscriptions() {
    final client = Supabase.instance.client;
    if (_membersChannel != null) {
      client.removeChannel(_membersChannel!);
      _membersChannel = null;
    }
    if (_sessionChannel != null) {
      client.removeChannel(_sessionChannel!);
      _sessionChannel = null;
    }
    if (_matchesChannel != null) {
      client.removeChannel(_matchesChannel!);
      _matchesChannel = null;
    }
  }

  Future<void> _refreshRoomDetails() async {
    if (_roomId == null) return;
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'room_manager',
        body: {
          'action': 'get_room',
          'payload': {'room_id': _roomId}
        }
      );
      final data = response.data;
      if (data != null) {
        if (data['members'] != null) {
          final List<dynamic> members = data['members'];
          _players = members.map((m) {
            final userMeta = m['users'] ?? {};
            final isYou = m['user_id'] == Supabase.instance.client.auth.currentUser?.id;
            return {
              'user_id': m['user_id'],
              'name': isYou ? '${userMeta['display_name'] ?? _myDisplayName ?? 'You'} (You)' : (userMeta['display_name'] ?? 'Friend'),
              'avatarUrl': userMeta['avatar_url'] ?? (isYou ? _myAvatarUrl : null) ?? 'https://api.dicebear.com/7.x/bottts/svg?seed=${m['user_id']}',
              'isReady': m['is_ready'] == true,
              'isYou': isYou,
            };
          }).toList();
        }

        final room = data['room'] ?? {};
        _isHost = room['host_id'] == Supabase.instance.client.auth.currentUser?.id;

        if (data['session'] != null) {
          _updateSessionFromDb(data['session']);
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error querying room stats: $e');
    }
  }

  void _updateSessionFromDb(Map<String, dynamic> data) {
    _sessionId = data['id'];
    _distanceRadius = (data['distance_km'] ?? 5).toDouble();
    _budgetIndex = _mapBudgetTierToIndex(data['budget_tier'] ?? 'BELOW_250');
    _selectedDietaryTags = List<String>.from(data['dietary_filters'] ?? []);
    _timerMinutes = data['swipe_time_limit_minutes'] ?? 5;
    _maxParticipants = data['max_players'] ?? 2;
    _matchedCuisine = data['selected_cuisine'];

    final phaseStr = data['current_phase'] ?? 'LOBBY';
    if (_currentPhase != phaseStr) {
      _currentPhase = phaseStr;
    }

    if (phaseStr == 'RESTAURANT_SWIPE' && _fetchedRestaurants.isEmpty && _matchedCuisine != null) {
      fetchRestaurantsForCuisine(_matchedCuisine!);
    }

    if (_sessionId != null && _matchesChannel == null) {
      _setupMatchesChannel(_sessionId!);
    }
    notifyListeners();
  }

  void _onMatchFound(Map<String, dynamic> record) {
    final rId = record['restaurant_id'];
    final rName = record['restaurant_name'];

    final matched = _fetchedRestaurants.firstWhere(
      (r) => r['id'] == rId,
      orElse: () => {
        'id': rId,
        'name': rName,
        'image': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=500',
        'rating': 4.5,
        'reviewsCount': 100,
        'distance': '1.2 km',
        'deliveryTime': '20-25 mins',
        'price': 'Below ₹500',
        'desc': 'Matched by your squad!',
        'popularDishes': [],
      },
    );

    _matchedRestaurant = matched;
    notifyListeners();
  }

  Future<void> _syncSettingsToBackend() async {
    if (_roomId == null || !_isHost) return;
    try {
      await Supabase.instance.client.functions.invoke(
        'session_manager',
        body: {
          'action': 'update_settings',
          'payload': {
            'room_id': _roomId,
            'distance_km': _distanceRadius.toInt(),
            'budget_tier': _mapBudgetIndexToTier(_budgetIndex),
            'dietary_filters': _selectedDietaryTags,
            'swipe_time_limit_minutes': _timerMinutes,
            'max_players': _maxParticipants,
          }
        }
      );
    } catch (e) {
      print('Failed to sync setting update: $e');
    }
  }

  String _mapBudgetIndexToTier(int index) {
    switch (index) {
      case 0: return 'BELOW_100';
      case 1: return 'BELOW_250';
      case 2: return 'BELOW_500';
      case 3: return 'BELOW_1000';
      case 4: return 'BELOW_2000';
      default: return 'BELOW_250';
    }
  }

  int _mapBudgetTierToIndex(String tier) {
    switch (tier) {
      case 'BELOW_100': return 0;
      case 'BELOW_250': return 1;
      case 'BELOW_500': return 2;
      case 'BELOW_1000': return 3;
      case 'BELOW_2000': return 4;
      default: return 1;
    }
  }


  @override
  void dispose() {
    _cancelRealtimeSubscriptions();
    super.dispose();
  }
}
