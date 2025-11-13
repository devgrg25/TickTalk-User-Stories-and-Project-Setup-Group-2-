import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class StopwatchPlayerMode extends StatefulWidget {
  final VoidCallback? onBack; // ✅ allows returning to MainPage
  final int playerCount; // supports 1–6 players

  const StopwatchPlayerMode({
    super.key,
    this.onBack,
    this.playerCount = 6,
  });

  @override
  State<StopwatchPlayerMode> createState() => _StopwatchPlayerModeState();
}

class _StopwatchPlayerModeState extends State<StopwatchPlayerMode>
    with TickerProviderStateMixin {
  late List<Stopwatch> _stopwatches;
  late List<Ticker> _tickers;
  late List<Duration> _elapsedTimes;
  late List<List<Duration>> _laps;
  late List<bool> _isRunning;

  @override
  void initState() {
    super.initState();
    final count = widget.playerCount.clamp(1, 6);
    _stopwatches = List.generate(count, (_) => Stopwatch());
    _tickers = List.generate(count, (i) => createTicker((_) => _onTick(i)));
    _elapsedTimes = List.generate(count, (_) => Duration.zero);
    _laps = List.generate(count, (_) => []);
    _isRunning = List.generate(count, (_) => false);
  }

  void _onTick(int index) {
    if (!mounted) return;
    setState(() {
      _elapsedTimes[index] = _stopwatches[index].elapsed;
    });
  }

  @override
  void dispose() {
    for (var ticker in _tickers) {
      ticker.dispose();
    }
    for (var sw in _stopwatches) {
      sw.stop();
    }
    super.dispose();
  }

  void _start(int i) {
    if (!_isRunning[i]) {
      _stopwatches[i].start();
      _tickers[i].start();
      setState(() => _isRunning[i] = true);
    }
  }

  void _stop(int i) {
    if (_isRunning[i]) {
      _stopwatches[i].stop();
      _tickers[i].stop();
      setState(() => _isRunning[i] = false);
    }
  }

  void _reset(int i) {
    _stopwatches[i].reset();
    _tickers[i].stop();
    _laps[i].clear();
    setState(() {
      _elapsedTimes[i] = Duration.zero;
      _isRunning[i] = false;
    });
  }

  void _lap(int i) {
    if (_isRunning[i]) {
      setState(() {
        _laps[i].add(_elapsedTimes[i]);
      });
    }
  }

  String _formatTime(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final cs = (d.inMilliseconds.remainder(1000) ~/ 10)
        .toString()
        .padLeft(2, '0');
    return "$m:$s:$cs";
  }

  List<_PlayerResult> _getLeaderboard() {
    final results = <_PlayerResult>[];
    for (int i = 0; i < _laps.length; i++) {
      if (_laps[i].isNotEmpty) {
        results.add(
            _PlayerResult(i + 1, _laps[i].last, _elapsedTimes[i]));
      }
    }
    results.sort((a, b) => a.lastLap.compareTo(b.lastLap));
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final leaderboard = _getLeaderboard();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Player Mode',
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Leaderboard Section
            if (leaderboard.isNotEmpty) ...[
              const Text(
                '🏁 Leaderboard',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: leaderboard.length,
                itemBuilder: (context, i) {
                  final r = leaderboard[i];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text('${i + 1}',
                            style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text('Player ${r.player}'),
                      subtitle: Text('Last Lap: ${_formatTime(r.lastLap)}'),
                      trailing: Text(
                        _formatTime(r.totalTime),
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
              const Divider(thickness: 1.5),
            ],

            // Player Stopwatch Cards
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _stopwatches.length,
              itemBuilder: (context, i) {
                return _buildPlayerCard(i);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(int i) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Player ${i + 1}',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                const Spacer(),
                Text(
                  _formatTime(_elapsedTimes[i]),
                  style: const TextStyle(
                      fontSize: 24,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                    'Lap', Icons.flag, Colors.blue, () => _lap(i)),
                _buildActionButton(
                  _isRunning[i] ? 'Stop' : 'Start',
                  _isRunning[i] ? Icons.pause : Icons.play_arrow,
                  _isRunning[i] ? Colors.orange : Colors.green,
                      () => _isRunning[i] ? _stop(i) : _start(i),
                ),
                _buildActionButton(
                    'Reset', Icons.refresh, Colors.red, () => _reset(i)),
              ],
            ),
            const SizedBox(height: 8),
            if (_laps[i].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const Text(
                    'Laps:',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 6),
                  Column(
                    children: List.generate(
                      _laps[i].length,
                          (index) => Text(
                        'Lap ${index + 1}: ${_formatTime(_laps[i][index])}',
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            color: Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _PlayerResult {
  final int player;
  final Duration lastLap;
  final Duration totalTime;
  _PlayerResult(this.player, this.lastLap, this.totalTime);
}
