import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum SortFilter {
  lowToHigh,
  highToLow,
  fastestTime,
  mostLaps,
}

class StopwatchPlayerMode extends StatefulWidget {
  final int playerCount;
  const StopwatchPlayerMode({super.key, required this.playerCount});

  @override
  State<StopwatchPlayerMode> createState() => _StopwatchPlayerModeState();
}

class _StopwatchPlayerModeState extends State<StopwatchPlayerMode>
    with TickerProviderStateMixin {
  late List<PlayerStopwatch> _players;
  final FlutterTts _tts = FlutterTts();
  bool _showSummary = false;
  SortFilter _currentFilter = SortFilter.fastestTime;

  @override
  void initState() {
    super.initState();
    _initTts();
    _players = List.generate(
      widget.playerCount,
          (index) => PlayerStopwatch(
        playerNumber: index + 1,
        vsync: this,
      ),
    );
    // Start all timers automatically
    for (var player in _players) {
      player.start();
    }
  }

  void _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.8);
  }

  @override
  void dispose() {
    _tts.stop();
    for (var player in _players) {
      player.dispose();
    }
    super.dispose();
  }

  void _stopAll() {
    for (var player in _players) {
      if (player.isRunning) {
        player.stop();
      }
    }
    _tts.speak('All timers stopped');
    setState(() => _showSummary = true);
  }

  List<PlayerStopwatch> _getSortedPlayers() {
    final players = List<PlayerStopwatch>.from(_players);

    switch (_currentFilter) {
      case SortFilter.lowToHigh:
        players.sort((a, b) => a.playerNumber.compareTo(b.playerNumber));
        break;
      case SortFilter.highToLow:
        players.sort((a, b) => b.playerNumber.compareTo(a.playerNumber));
        break;
      case SortFilter.fastestTime:
        players.sort((a, b) => a.finalTime.compareTo(b.finalTime));
        break;
      case SortFilter.mostLaps:
        players.sort((a, b) => b.laps.length.compareTo(a.laps.length));
        break;
    }

    return players;
  }

  @override
  Widget build(BuildContext context) {
    if (_showSummary) {
      return _buildSummaryScreen();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Player Mode (${widget.playerCount} Players)',
          style: const TextStyle(color: Colors.black, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: widget.playerCount,
              itemBuilder: (context, index) {
                return _buildPlayerCard(_players[index]);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _stopAll,
                  icon: const Icon(Icons.stop_circle, size: 28),
                  label: const Text(
                    'Stop All Timers',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(PlayerStopwatch player) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: player.isRunning ? Colors.green : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Player Header with Lap Count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Player ${player.playerNumber}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007BFF),
                  ),
                ),
                if (player.laps.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007BFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${player.laps.length} lap${player.laps.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF007BFF),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Horizontal Layout: Timer + Buttons
            Row(
              children: [
                // Timer Display
                Expanded(
                  flex: 2,
                  child: StreamBuilder<Duration>(
                    stream: player.elapsedStream,
                    initialData: Duration.zero,
                    builder: (context, snapshot) {
                      final elapsed = snapshot.data ?? Duration.zero;
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            _formatTime(elapsed),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Buttons Column
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildCompactButton(
                        icon: player.isRunning ? Icons.pause : Icons.play_arrow,
                        label: player.isRunning ? 'Stop' : 'Start',
                        onPressed: () => _togglePlayer(player),
                        color: player.isRunning ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(height: 6),
                      _buildCompactButton(
                        icon: Icons.refresh,
                        label: 'Reset',
                        onPressed: () => _resetPlayer(player),
                        color: Colors.red,
                      ),
                      const SizedBox(height: 6),
                      _buildCompactButton(
                        icon: Icons.flag,
                        label: 'Lap',
                        onPressed: player.isRunning ? () => _lap(player) : null,
                        color: const Color(0xFF007BFF),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null ? color : Colors.grey.shade300,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: onPressed != null ? 2 : 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _togglePlayer(PlayerStopwatch player) {
    setState(() {
      if (player.isRunning) {
        player.stop();
        _tts.speak('Player ${player.playerNumber} stopped');
      } else {
        player.start();
        _tts.speak('Player ${player.playerNumber} started');
      }
    });
  }

  void _resetPlayer(PlayerStopwatch player) {
    setState(() {
      player.reset();
    });
    _tts.speak('Player ${player.playerNumber} reset');
  }

  void _lap(PlayerStopwatch player) {
    setState(() {
      player.lap();
    });
    _tts.speak('Lap ${player.laps.length}');
  }

  Widget _buildSummaryScreen() {
    final sortedPlayers = _getSortedPlayers();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Final Results', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<SortFilter>(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onSelected: (filter) {
              setState(() => _currentFilter = filter);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: SortFilter.lowToHigh,
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_upward,
                      color: _currentFilter == SortFilter.lowToHigh
                          ? const Color(0xFF007BFF)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Player # Low to High'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortFilter.highToLow,
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_downward,
                      color: _currentFilter == SortFilter.highToLow
                          ? const Color(0xFF007BFF)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Player # High to Low'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortFilter.fastestTime,
                child: Row(
                  children: [
                    Icon(
                      Icons.speed,
                      color: _currentFilter == SortFilter.fastestTime
                          ? const Color(0xFF007BFF)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Fastest Time'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortFilter.mostLaps,
                child: Row(
                  children: [
                    Icon(
                      Icons.flag,
                      color: _currentFilter == SortFilter.mostLaps
                          ? const Color(0xFF007BFF)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Most Laps'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 64,
                  color: Colors.amber,
                ),
                const SizedBox(height: 12),
                const Text(
                  '🏆 Leaderboard 🏆',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.playerCount} Players • ${_getFilterLabel()}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),

          // Results List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: sortedPlayers.length,
              itemBuilder: (context, index) {
                final player = sortedPlayers[index];
                final position = index + 1;

                // Show medals and colors for top 3 positions in ALL filters
                Color positionColor;
                String medal;

                if (position == 1) {
                  positionColor = Colors.amber;
                  medal = '🥇';
                } else if (position == 2) {
                  positionColor = Colors.grey.shade600;
                  medal = '🥈';
                } else if (position == 3) {
                  positionColor = Colors.brown;
                  medal = '🥉';
                } else {
                  positionColor = const Color(0xFF007BFF);
                  medal = '';
                }

                return _buildPlayerResultCard(
                  player: player,
                  position: position,
                  positionColor: positionColor,
                  medal: medal,
                );
              },
            ),
          ),

          // Close Button
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 24),
                  label: const Text(
                    'Close',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007BFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel() {
    switch (_currentFilter) {
      case SortFilter.lowToHigh:
        return 'Sorted by Player #';
      case SortFilter.highToLow:
        return 'Sorted by Player # (desc)';
      case SortFilter.fastestTime:
        return 'Sorted by Fastest Time';
      case SortFilter.mostLaps:
        return 'Sorted by Most Laps';
    }
  }

  Widget _buildPlayerResultCard({
    required PlayerStopwatch player,
    required int position,
    required Color positionColor,
    required String medal,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: positionColor,
              child: Text(
                '$position',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (medal.isNotEmpty)
              Positioned(
                top: -4,
                right: -4,
                child: Text(medal, style: const TextStyle(fontSize: 18)),
              ),
          ],
        ),
        title: Text(
          'Player ${player.playerNumber}',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Time: ${_formatTime(player.finalTime)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              'Laps: ${player.laps.length}',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        children: player.laps.isEmpty
            ? [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No laps recorded',
              style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
            ),
          ),
        ]
            : [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const Text(
                  'Lap Times:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007BFF),
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(player.laps.length, (index) {
                  final lapNumber = index + 1;
                  final lapTime = player.laps[index];
                  final lapDuration = index == 0
                      ? lapTime
                      : Duration(
                      milliseconds: lapTime.inMilliseconds -
                          player.laps[index - 1].inMilliseconds);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFF007BFF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '$lapNumber',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF007BFF),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total: ${_formatTime(lapTime)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Split: ${_formatTime(lapDuration)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Icon(
                          Icons.flag,
                          color: Colors.grey.shade400,
                          size: 18,
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final centiseconds =
    (duration.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds:$centiseconds';
  }
}

// Player Stopwatch Class
class PlayerStopwatch {
  final int playerNumber;
  late Ticker _ticker;
  final Stopwatch _stopwatch = Stopwatch();
  final List<Duration> laps = [];
  bool isRunning = false;
  Duration finalTime = Duration.zero;

  final _elapsedController = StreamController<Duration>.broadcast();
  Stream<Duration> get elapsedStream => _elapsedController.stream;

  Duration _lastAnnouncedTime = Duration.zero;
  final FlutterTts _tts = FlutterTts();

  PlayerStopwatch({required this.playerNumber, required TickerProvider vsync}) {
    _ticker = vsync.createTicker(_onTick);
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.5);
  }

  void _onTick(Duration elapsed) {
    final currentElapsed = _stopwatch.elapsed;
    _elapsedController.add(currentElapsed);
    _checkTimeAnnouncement(currentElapsed);
  }

  void start() {
    if (!isRunning) {
      _stopwatch.start();
      _ticker.start();
      isRunning = true;
    }
  }

  void _checkTimeAnnouncement(Duration elapsed) {
    final currentSeconds = elapsed.inSeconds;
    final lastAnnouncedSeconds = _lastAnnouncedTime.inSeconds;

    if (currentSeconds > 0 &&
        currentSeconds % 30 == 0 &&
        currentSeconds != lastAnnouncedSeconds) {
      _lastAnnouncedTime = elapsed;
      _announceTime(elapsed);
    }
  }

  Future<void> _announceTime(Duration elapsed) async {
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds.remainder(60);

    String announcement = "Player $playerNumber: ";
    if (minutes > 0) {
      announcement += "$minutes minute${minutes != 1 ? 's' : ''} and $seconds second${seconds != 1 ? 's' : ''}";
    } else {
      announcement += "$seconds second${seconds != 1 ? 's' : ''}";
    }

    await _tts.speak(announcement);
  }

  void stop() {
    if (isRunning) {
      _stopwatch.stop();
      _ticker.stop();
      isRunning = false;
      finalTime = _stopwatch.elapsed;
    }
  }

  void reset() {
    _stopwatch.reset();
    laps.clear();
    _lastAnnouncedTime = Duration.zero;
    finalTime = Duration.zero;
    if (isRunning) {
      _ticker.stop();
      isRunning = false;
    }
    _elapsedController.add(Duration.zero);
  }

  void lap() {
    if (isRunning) {
      laps.add(_stopwatch.elapsed);
    }
  }

  void dispose() {
    _elapsedController.close();
    _ticker.dispose();
    _stopwatch.stop();
    _tts.stop();
  }
}