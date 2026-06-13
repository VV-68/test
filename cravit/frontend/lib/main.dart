import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'theme/app_theme.dart';
import 'models/room_state.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/filters_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/swipe_cuisines_screen.dart';
import 'screens/match_transition_screen.dart';
import 'screens/swipe_restaurants_screen.dart';
import 'screens/final_match_screen.dart';
import 'screens/roulette_screen.dart';
import 'screens/no_match_screen.dart';
import 'screens/who_pays_screen.dart';
import 'screens/squads_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/waiting_swipes_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => RoomState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<RoomState>(context);
    return MaterialApp(
      title: 'Cravit',
      debugShowCheckedModeBanner: false,
      themeMode: state.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/filters': (context) => const FiltersScreen(),
        '/lobby': (context) => const LobbyScreen(),
        '/swipe-cuisines': (context) => const SwipeCuisinesScreen(),
        '/match-transition': (context) => const MatchTransitionScreen(),
        '/swipe-restaurants': (context) => const SwipeRestaurantsScreen(),
        '/final-match': (context) => const FinalMatchScreen(),
        '/roulette': (context) => const RouletteScreen(),
        '/no-match': (context) => const NoMatchScreen(),
        '/who-pays': (context) => const WhoPaysScreen(),
        '/squads': (context) => const SquadsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/waiting-swipes': (context) => const WaitingSwipesScreen(),
      },
    );
  }
}
