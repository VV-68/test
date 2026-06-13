import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/room_state.dart';
import '../theme/app_theme.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<RoomState>(context, listen: false);
      state.addListener(_stateListener);
    });
  }

  void _stateListener() {
    if (!mounted) return;
    final state = Provider.of<RoomState>(context, listen: false);
    if (state.currentPhase == 'CUISINE_SWIPE') {
      state.removeListener(_stateListener);
      Navigator.of(context).pushReplacementNamed('/swipe-cuisines');
    }
  }

  @override
  void dispose() {
    try {
      final state = Provider.of<RoomState>(context, listen: false);
      state.removeListener(_stateListener);
    } catch (_) {}
    super.dispose();
  }

  void _copyToClipboard(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Room code copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<RoomState>(context);
    final roomCode = state.roomCode ?? '-----';
    final players = state.players;
    
    // Check if swipe session is ready to start:
    // Need at least 2 players, and everyone must be ready.
    final bool canStart = players.length >= 2 && players.every((p) => p['isReady'] == true);

    // Look up my own player entry to find readiness status
    final myPlayer = players.firstWhere((p) => p['isYou'] == true, orElse: () => {});
    final bool isIReady = myPlayer['isReady'] == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matchmaking Lobby'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textWhite),
          onPressed: () {
            state.leaveRoom();
            Navigator.of(context).popUntil(ModalRoute.withName('/home'));
          },
        ),
      ),
      body: Container(
        color: AppTheme.bgObsidian,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.cardObsidian,
                          border: Border.all(color: AppTheme.borderGray),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryCoral,
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Waiting for Players...',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Share this room code with your friends to join.',
                        style: TextStyle(color: AppTheme.textGray, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Room Code Card
                      InkWell(
                        onTap: () => _copyToClipboard(context, roomCode),
                        borderRadius: BorderRadius.circular(20),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                          decoration: BoxDecoration(
                            color: AppTheme.cardObsidian,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.borderGray),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ROOM CODE',
                                    style: TextStyle(
                                      color: AppTheme.textGray,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    roomCode,
                                    style: const TextStyle(
                                      color: AppTheme.primaryCoral,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 6.0,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.cardObsidianLight,
                                ),
                                child: Icon(Icons.copy, color: AppTheme.textWhite, size: 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Player List Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Squad Members (${players.length})',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                          ),
                          if (players.length < 2)
                            const Row(
                              children: [
                                Icon(Icons.info_outline, color: AppTheme.primaryCoral, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Need 2+ players',
                                  style: TextStyle(color: AppTheme.primaryCoral, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Player List Items
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: players.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final player = players[index];
                          final isReady = player['isReady'] == true;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.cardObsidian,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.borderGray),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppTheme.cardObsidianLight,
                                  child: ClipOval(
                                    child: player['avatarUrl'] != null && player['avatarUrl'].startsWith('assets/')
                                        ? Image.asset(
                                            player['avatarUrl'],
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.network(
                                            player['avatarUrl'] ?? 'https://api.dicebear.com/7.x/bottts/svg?seed=friend',
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Icon(Icons.person, color: AppTheme.textGray),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        player['name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        isReady ? 'Ready' : 'Joining...',
                                        style: TextStyle(
                                          color: isReady ? AppTheme.likeGreen : AppTheme.textGray,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isReady
                                        ? AppTheme.likeGreen.withOpacity(0.12)
                                        : Colors.amber.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isReady ? 'READY' : 'WAITING',
                                    style: TextStyle(
                                      color: isReady ? AppTheme.likeGreen : Colors.amber,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Button Panel (Host vs Guest)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: (state.isHost ? canStart : true)
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryCoral.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: state.isHost
                      ? ElevatedButton(
                          onPressed: canStart
                              ? () {
                                  state.startSession();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            backgroundColor: canStart ? AppTheme.primaryCoral : AppTheme.cardObsidian,
                            disabledBackgroundColor: AppTheme.cardObsidian.withOpacity(0.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Start Swipe Session',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: canStart ? AppTheme.textWhite : AppTheme.textGray,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.play_arrow,
                                size: 20,
                                color: canStart ? AppTheme.textWhite : AppTheme.textGray,
                              ),
                            ],
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () {
                            state.toggleReady(!isIReady);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            backgroundColor: isIReady ? AppTheme.likeGreen : AppTheme.primaryCoral,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isIReady ? 'YOU ARE READY (TOGGLE)' : 'TAP TO GET READY',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textWhite,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isIReady ? Icons.check_circle : Icons.hail,
                                size: 20,
                                color: AppTheme.textWhite,
                              ),
                            ],
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
}
