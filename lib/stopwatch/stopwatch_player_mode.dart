// player_mode.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _showSummary = false;
  SortFilter _currentFilter = SortFilter.fastestTime;

  // Voice control
  bool _isListening = false;
  String _lastRecognizedCommand = '';

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSpeech();
    _players = List.generate(
      widget.playerCount,
          (index) => PlayerStopwatch(
        playerNumber: index + 1,
        vsync: this,
      ),
    );
    for (var player in _players) {
      player.start();
    }
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.8);
  }

  Future<void> _initSpeech() async {
    await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' && mounted && !_showSummary) {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isListening = false);
        }
      },
    );
  }

  @override
  void dispose() {
    _tts.stop();
    _speech.stop();
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

  void _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    await _tts.stop();

    if (!_speech.isAvailable) {
      await _initSpeech();
    }

    if (_speech.isAvailable && !_isListening) {
      setState(() => _isListening = true);

      try {
        await _speech.listen(
          onResult: (result) {
            final words = result.recognizedWords.toLowerCase().trim();
            if (result.finalResult && words.isNotEmpty) {
              setState(() => _lastRecognizedCommand = words);
              _handleVoiceCommand(words);
            } else if (words.isNotEmpty) {
              setState(() => _lastRecognizedCommand = '$words...');
            }
          },
          listenFor: const Duration(minutes: 10),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.confirmation,
        );
      } catch (e) {
        setState(() => _isListening = false);
      }
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    await _tts.stop();
    setState(() {
      _isListening = false;
      _lastRecognizedCommand = '';
    });
  }

  int? _extractPlayerNumber(String command) {
    final patterns = [
      RegExp(r'player\s*(\d+)'),
      RegExp(r'player\s*(one|two|three|four|five|six|seven|eight|nine|ten)'),
      RegExp(r'^(\d+)\s'),
      RegExp(r'\s(\d+)\s'),
    ];

    final numberWords = {
      'one': 1, 'two': 2, 'three': 3,
      'four': 4, 'five': 5, 'six': 6,
      'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10
    };

    for (var pattern in patterns) {
      final match = pattern.firstMatch(command);
      if (match != null) {
        final captured = match.group(1);
        if (captured != null) {
          final num = int.tryParse(captured);
          if (num != null && num >= 1 && num <= widget.playerCount) {
            return num;
          }
          if (numberWords.containsKey(captured)) {
            final num = numberWords[captured]!;
            if (num <= widget.playerCount) {
              return num;
            }
          }
        }
      }
    }
    return null;
  }

  Future<void> _handleVoiceCommand(String command) async {
    bool commandRecognized = false;
    final normalized = command.toLowerCase();

    // If in summary mode, check summary-specific questions first
    if (_showSummary) {
      final answer = _answerSummaryQuestion(normalized);
      if (answer != null) {
        await _tts.speak(answer);
        commandRecognized = true;
        return;
      }
    }

    // Attempt to extract a player number from the command
    final playerNum = _extractPlayerNumber(normalized);

    if (playerNum != null) {
      final player = _players[playerNum - 1];

      // show/collapse laps commands
      if (normalized.contains('show laps') || normalized.contains('expand laps') || normalized.contains('open laps') || normalized.contains('show me laps')) {
        setState(() => player.showLaps = true);
        await _tts.speak('Showing laps for player $playerNum');
        commandRecognized = true;
        return;
      }
      if (normalized.contains('hide laps') || normalized.contains('collapse laps') || normalized.contains('close laps')) {
        setState(() => player.showLaps = false);
        await _tts.speak('Hiding laps for player $playerNum');
        commandRecognized = true;
        return;
      }

      // Specific player details request in summary mode (already handled earlier if _showSummary)
      if (_showSummary && (normalized.contains('details') || normalized.contains('about') ||
          normalized.contains('give me') || normalized.contains('tell me'))) {
        final details = _getPlayerDetails(player);
        await _tts.speak(details);
        commandRecognized = true;
        return;
      }

      // Start/Stop/Lap/Reset for specific player
      if (normalized.contains('start') || normalized.contains('begin') || normalized.contains('go')) {
        if (!player.isRunning) {
          setState(() => player.start());
          await _tts.speak('Player $playerNum started');
          commandRecognized = true;
        } else {
          // already running
          await _tts.speak('Player $playerNum is already running');
          commandRecognized = true;
        }
      } else if (normalized.contains('stop') || normalized.contains('pause')) {
        if (player.isRunning) {
          setState(() => player.stop());
          await _tts.speak('Player $playerNum stopped');
          commandRecognized = true;
        } else {
          await _tts.speak('Player $playerNum is already stopped');
          commandRecognized = true;
        }
      } else if ((normalized.contains('lap') || normalized.contains('flag') || normalized.contains('mark')) &&
          !normalized.contains('black') && !normalized.contains('clap')) {
        if (player.isRunning) {
          setState(() => player.lap());
          await _tts.speak('Player $playerNum lap ${player.laps.length}');
          commandRecognized = true;
        } else {
          await _tts.speak('Player $playerNum is not running');
          commandRecognized = true;
        }
      } else if (normalized.contains('reset') || normalized.contains('clear')) {
        setState(() => player.reset());
        await _tts.speak('Player $playerNum reset');
        commandRecognized = true;
      } else if (normalized.contains('highest lap') || normalized.contains('biggest lap') || normalized.contains('largest lap')) {
        final pair = _getPlayerHighestLap(player);
        if (pair != null) {
          final lapIndex = pair.item1;
          final lapDuration = pair.item2;
          await _tts.speak('Player $playerNum highest lap is ${_formatTimeForSpeech(lapDuration)} at lap ${lapIndex + 1}');
        } else {
          await _tts.speak('No laps recorded for player $playerNum');
        }
        commandRecognized = true;
      } else if (normalized.contains('lowest lap') || normalized.contains('smallest lap') || normalized.contains('shortest lap')) {
        final pair = _getPlayerLowestLap(player);
        if (pair != null) {
          final lapIndex = pair.item1;
          final lapDuration = pair.item2;
          await _tts.speak('Player $playerNum lowest lap is ${_formatTimeForSpeech(lapDuration)} at lap ${lapIndex + 1}');
        } else {
          await _tts.speak('No laps recorded for player $playerNum');
        }
        commandRecognized = true;
      }
    } else {
      // Global commands (no player number)
      if (normalized.contains('stop all') || normalized.contains('stop everyone') || normalized.contains('stop all timers')) {
        _stopAll();
        commandRecognized = true;
      } else if (normalized.contains('who is fastest') || normalized.contains('who was fastest') || normalized.contains('fastest player') || normalized.contains('who won') || normalized.contains('winner')) {
        final fastest = _getFastestPlayer();
        if (fastest != null) {
          await _tts.speak('Player ${fastest.playerNumber} was the fastest with a time of ${_formatTimeForSpeech(fastest.finalTime)}');
        } else {
          await _tts.speak('I could not determine the fastest player yet.');
        }
        commandRecognized = true;
      } else if (normalized.contains('who is slowest') || normalized.contains('slowest player') || normalized.contains('who was slowest')) {
        final slowest = _getSlowestPlayer();
        if (slowest != null) {
          await _tts.speak('Player ${slowest.playerNumber} was the slowest with a time of ${_formatTimeForSpeech(slowest.finalTime)}');
        } else {
          await _tts.speak('I could not determine the slowest player yet.');
        }
        commandRecognized = true;
      } else if (normalized.contains('highest lap') || normalized.contains('biggest lap') || normalized.contains('largest lap')) {
        final player = _getPlayerWithHighestLap();
        if (player != null) {
          final pair = _getPlayerHighestLap(player)!;
          await _tts.speak('Player ${player.playerNumber} had the highest lap: ${_formatTimeForSpeech(pair.item2)} (lap ${pair.item1 + 1})');
        } else {
          await _tts.speak('No lap data to determine highest lap.');
        }
        commandRecognized = true;
      } else if (normalized.contains('lowest lap') || normalized.contains('smallest lap') || normalized.contains('shortest lap')) {
        final player = _getPlayerWithLowestLap();
        if (player != null) {
          final pair = _getPlayerLowestLap(player)!;
          await _tts.speak('Player ${player.playerNumber} had the lowest lap: ${_formatTimeForSpeech(pair.item2)} (lap ${pair.item1 + 1})');
        } else {
          await _tts.speak('No lap data to determine lowest lap.');
        }
        commandRecognized = true;
      } else if (normalized.contains('show summary') || normalized.contains('summary') || normalized.contains('results') || normalized.contains('leaderboard') || normalized.contains('who was fastest') || normalized.contains('who was slowest')) {
        // Show summary routines
        setState(() => _showSummary = true);
        await Future.delayed(const Duration(milliseconds: 300));
        final summary = _answerSummaryQuestion('summary');
        if (summary != null) await _tts.speak(summary);
        commandRecognized = true;
      }
    }

    if (!commandRecognized) {
      if (_showSummary) {
        await _tts.speak("I can answer questions about the results. Try asking who was fastest, who was slowest, compare players, or ask about a specific player.");
      } else {
        await _tts.speak("Sorry, I didn't understand. Say player number and command, like 'player 1 start', '2 lap', or say 'stop all'.");
      }
    }
  }

  String? _answerSummaryQuestion(String command) {
    final normalized = command.toLowerCase();

    // Helper function to convert word numbers to digits
    int? _parsePlayerNumberWord(String text) {
      final wordToNumber = {
        'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
        'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
        '1': 1, '2': 2, '3': 3, '4': 4, '5': 5,
        '6': 6, '7': 7, '8': 8, '9': 9, '10': 10,
      };

      final words = text.split(' ');
      for (int i = 0; i < words.length; i++) {
        if (words[i] == 'player' && i + 1 < words.length) {
          final nextWord = words[i + 1].replaceAll(RegExp(r'[^\w]'), ''); // Remove punctuation
          if (wordToNumber.containsKey(nextWord)) {
            return wordToNumber[nextWord];
          }
        }
      }
      return null;
    }

// Compare two players
    if (normalized.contains('compare')) {
      // Extract all player numbers (both words and digits)
      final playerNumbers = <int>[];
      final words = normalized.split(' ');

      for (int i = 0; i < words.length; i++) {
        if (words[i] == 'player' && i + 1 < words.length) {
          final nextWord = words[i + 1].replaceAll(RegExp(r'[^\w]'), '');

          // Try parsing as number word first
          final wordToNumber = {
            'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
            'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
          };

          int? num = wordToNumber[nextWord];

          // If not a word, try parsing as digit
          num ??= int.tryParse(nextWord);

          if (num != null && num >= 1 && num <= _players.length && !playerNumbers.contains(num)) {
            playerNumbers.add(num);
          }
        }
      }

      // Check if we have both valid player numbers
      if (playerNumbers.length == 2) {
        return _compareTwoPlayers(playerNumbers[0], playerNumbers[1]);
      } else if (playerNumbers.length == 1) {
        return 'Please specify a second player to compare. For example, say "compare player ${playerNumbers[0]} and player ${playerNumbers[0] == 1 ? 2 : 1}"';
      }
      return 'Please specify which two players to compare. For example, say "compare player 1 and player 2"';
    }
    // Show specific player's laps
    if (normalized.contains('show') && normalized.contains('lap')) {
      final playerNum = _extractPlayerNumber(normalized);
      if (playerNum != null) {
        final player = _players[playerNum - 1];
        setState(() => player.showLaps = true);
        return 'Showing laps for player $playerNum';
      }
    }

    // Fastest player (by finalTime)
    if (normalized.contains('fastest') || normalized.contains('quickest') ||
        normalized.contains('who won') || normalized.contains('winner')) {
      final fastest = _getFastestPlayer();
      if (fastest != null) {
        return 'Player ${fastest.playerNumber} was the fastest with a time of ${_formatTimeForSpeech(fastest.finalTime)}';
      }
      return null;
    }

    // Slowest player
    if (normalized.contains('slowest') || normalized.contains('last place') ||
        normalized.contains('who was slow')) {
      final slowest = _getSlowestPlayer();
      if (slowest != null) {
        return 'Player ${slowest.playerNumber} was the slowest with a time of ${_formatTimeForSpeech(slowest.finalTime)}';
      }
      return null;
    }

    // Most laps
    if (normalized.contains('most laps') || normalized.contains('most lap')) {
      final mostLaps = _players.reduce((a, b) =>
      a.laps.length > b.laps.length ? a : b);
      return 'Player ${mostLaps.playerNumber} recorded the most laps with ${mostLaps.laps.length} lap${mostLaps.laps.length != 1 ? 's' : ''}';
    }

    // Least laps
    if (normalized.contains('least laps') || normalized.contains('fewest laps')) {
      final leastLaps = _players.reduce((a, b) =>
      a.laps.length < b.laps.length ? a : b);
      return 'Player ${leastLaps.playerNumber} recorded the fewest laps with ${leastLaps.laps.length} lap${leastLaps.laps.length != 1 ? 's' : ''}';
    }

    // Highest single lap across players
    if (normalized.contains('highest lap') || normalized.contains('biggest lap') || normalized.contains('largest lap')) {
      final player = _getPlayerWithHighestLap();
      if (player != null) {
        final pair = _getPlayerHighestLap(player)!;
        return 'Player ${player.playerNumber} had the highest lap at ${_formatTimeForSpeech(pair.item2)} (lap ${pair.item1 + 1})';
      }
      return 'No lap data available';
    }

    // Lowest single lap across players
    if (normalized.contains('lowest lap') || normalized.contains('smallest lap') || normalized.contains('shortest lap')) {
      final player = _getPlayerWithLowestLap();
      if (player != null) {
        final pair = _getPlayerLowestLap(player)!;
        return 'Player ${player.playerNumber} had the lowest lap at ${_formatTimeForSpeech(pair.item2)} (lap ${pair.item1 + 1})';
      }
      return 'No lap data available';
    }

    // Summary of all players
    if (normalized.contains('summary') || normalized.contains('all players') ||
        normalized.contains('everyone') || normalized.contains('results')) {
      final sorted = List<PlayerStopwatch>.from(_players)
        ..sort((a, b) => a.finalTime.compareTo(b.finalTime));

      String summary = 'Here are the results. ';
      for (int i = 0; i < sorted.length; i++) {
        final p = sorted[i];
        summary += 'Player ${p.playerNumber}: ${_formatTimeForSpeech(p.finalTime)} with ${p.laps.length} lap${p.laps.length != 1 ? 's' : ''}. ';
      }
      return summary;
    }

    return null;
  }

  String _compareTwoPlayers(int player1Num, int player2Num) {
    final player1 = _players[player1Num - 1];
    final player2 = _players[player2Num - 1];

    String comparison = 'Comparing player $player1Num and player $player2Num. ';

    // Compare final times
    final timeDiff = (player1.finalTime - player2.finalTime).abs();
    final timeDiffReadable = _formatTimeForSpeech(timeDiff);

    if (player1.finalTime < player2.finalTime) {
      comparison += 'Player $player1Num was faster by $timeDiffReadable. ';
    } else if (player2.finalTime < player1.finalTime) {
      comparison += 'Player $player2Num was faster by $timeDiffReadable. ';
    } else {
      comparison += 'They finished at the same time. ';
    }

    // Final times
    comparison += 'Player $player1Num finished in ${_formatTimeForSpeech(player1.finalTime)}, ';
    comparison += 'and player $player2Num finished in ${_formatTimeForSpeech(player2.finalTime)}. ';

    // Compare lap counts
    if (player1.laps.length != player2.laps.length) {
      comparison += 'Player $player1Num recorded ${player1.laps.length} lap${player1.laps.length != 1 ? 's' : ''}, ';
      comparison += 'while player $player2Num recorded ${player2.laps.length} lap${player2.laps.length != 1 ? 's' : ''}. ';
    } else {
      comparison += 'Both recorded ${player1.laps.length} lap${player1.laps.length != 1 ? 's' : ''}. ';
    }

    // Compare average lap times
    if (player1.laps.isNotEmpty && player2.laps.isNotEmpty) {
      final avg1 = Duration(milliseconds: player1.finalTime.inMilliseconds ~/ player1.laps.length);
      final avg2 = Duration(milliseconds: player2.finalTime.inMilliseconds ~/ player2.laps.length);

      final avgDiff = (avg1 - avg2).abs();

      if (avg1 < avg2) {
        comparison += 'Player $player1Num had a better average lap time of ${_formatTimeForSpeech(avg1)}, ';
        comparison += 'compared to player $player2Num at ${_formatTimeForSpeech(avg2)}. ';
      } else if (avg2 < avg1) {
        comparison += 'Player $player2Num had a better average lap time of ${_formatTimeForSpeech(avg2)}, ';
        comparison += 'compared to player $player1Num at ${_formatTimeForSpeech(avg1)}. ';
      } else {
        comparison += 'Both had the same average lap time. ';
      }
    }

    // Compare best laps
    final best1 = _getPlayerLowestLap(player1);
    final best2 = _getPlayerLowestLap(player2);

    if (best1 != null && best2 != null) {
      if (best1.item2 < best2.item2) {
        comparison += 'Player $player1Num had the fastest single lap at ${_formatTimeForSpeech(best1.item2)}. ';
      } else if (best2.item2 < best1.item2) {
        comparison += 'Player $player2Num had the fastest single lap at ${_formatTimeForSpeech(best2.item2)}. ';
      } else {
        comparison += 'Both had the same best lap time. ';
      }
    }

    return comparison;
  }

  String _formatTimeForSpeech(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    final centiseconds = (duration.inMilliseconds.remainder(1000) ~/ 10);

    if (minutes > 0) {
      if (seconds > 0) {
        return '$minutes minute${minutes != 1 ? 's' : ''} and $seconds second${seconds != 1 ? 's' : ''}';
      } else {
        return '$minutes minute${minutes != 1 ? 's' : ''}';
      }
    } else {
      if (centiseconds > 0) {
        return '$seconds point $centiseconds seconds';
      } else {
        return '$seconds second${seconds != 1 ? 's' : ''}';
      }
    }
  }

  String _getPlayerDetails(PlayerStopwatch player) {
    String details = 'Player ${player.playerNumber} details: ';
    details += 'Final time: ${_formatTime(player.finalTime)}. ';
    details += 'Total laps: ${player.laps.length}. ';

    if (player.laps.isNotEmpty) {
      details += 'Lap times: ';
      for (int i = 0; i < player.laps.length; i++) {
        final lapTime = i == 0
            ? player.laps[i]
            : Duration(milliseconds: player.laps[i].inMilliseconds - player.laps[i - 1].inMilliseconds);
        details += 'Lap ${i + 1}: ${_formatTime(lapTime)}. ';
      }
      // highest / lowest lap for this player
      final highest = _getPlayerHighestLap(player);
      final lowest = _getPlayerLowestLap(player);
      if (highest != null) {
        details += 'Highest lap: ${_formatTime(highest.item2)} (lap ${highest.item1 + 1}). ';
      }
      if (lowest != null) {
        details += 'Lowest lap: ${_formatTime(lowest.item2)} (lap ${lowest.item1 + 1}). ';
      }
    } else {
      details += 'No laps recorded. ';
    }

    return details;
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

  // Helpers to fetch fastest/slowest player by finalTime
  PlayerStopwatch? _getFastestPlayer() {
    final valid = _players.where((p) => p.finalTime > Duration.zero).toList();
    if (valid.isEmpty) return null;
    valid.sort((a, b) => a.finalTime.compareTo(b.finalTime));
    return valid.first;
  }

  PlayerStopwatch? _getSlowestPlayer() {
    final valid = _players.where((p) => p.finalTime > Duration.zero).toList();
    if (valid.isEmpty) return null;
    valid.sort((a, b) => b.finalTime.compareTo(a.finalTime));
    return valid.first;
  }

  // For single-lap extremes across all players
  PlayerStopwatch? _getPlayerWithHighestLap() {
    PlayerStopwatch? best;
    Duration? bestDur;
    for (var p in _players) {
      for (int i = 0; i < p.laps.length; i++) {
        final lapDur = i == 0
            ? p.laps[i]
            : Duration(milliseconds: p.laps[i].inMilliseconds - p.laps[i - 1].inMilliseconds);
        if (bestDur == null || lapDur > bestDur) {
          bestDur = lapDur;
          best = p;
        }
      }
    }
    return best;
  }

  PlayerStopwatch? _getPlayerWithLowestLap() {
    PlayerStopwatch? best;
    Duration? bestDur;
    for (var p in _players) {
      for (int i = 0; i < p.laps.length; i++) {
        final lapDur = i == 0
            ? p.laps[i]
            : Duration(milliseconds: p.laps[i].inMilliseconds - p.laps[i - 1].inMilliseconds);
        if (bestDur == null || lapDur < bestDur) {
          bestDur = lapDur;
          best = p;
        }
      }
    }
    return best;
  }

  // Returns pair (index, duration) for highest lap of a given player
  _ItemPair? _getPlayerHighestLap(PlayerStopwatch player) {
    if (player.laps.isEmpty) return null;
    int bestIndex = 0;
    Duration bestDur = Duration.zero;
    for (int i = 0; i < player.laps.length; i++) {
      final lapDur = i == 0
          ? player.laps[i]
          : Duration(milliseconds: player.laps[i].inMilliseconds - player.laps[i - 1].inMilliseconds);
      if (i == 0 || lapDur > bestDur) {
        bestDur = lapDur;
        bestIndex = i;
      }
    }
    return _ItemPair(bestIndex, bestDur);
  }

  _ItemPair? _getPlayerLowestLap(PlayerStopwatch player) {
    if (player.laps.isEmpty) return null;
    int bestIndex = 0;
    Duration bestDur = Duration.zero;
    for (int i = 0; i < player.laps.length; i++) {
      final lapDur = i == 0
          ? player.laps[i]
          : Duration(milliseconds: player.laps[i].inMilliseconds - player.laps[i - 1].inMilliseconds);
      if (i == 0 || lapDur < bestDur) {
        bestDur = lapDur;
        bestIndex = i;
      }
    }
    return _ItemPair(bestIndex, bestDur);
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
        leading: BackButton(
          color: Colors.black,
          onPressed: () {
            _tts.stop();
            _speech.stop();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          if (_lastRecognizedCommand.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF007BFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF007BFF).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Heard:',
                    style: TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _lastRecognizedCommand,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF007BFF), fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 170),
              itemCount: widget.playerCount,
              itemBuilder: (context, index) {
                return _buildPlayerCard(_players[index]);
              },
            ),
          ),
        ],
      ),
      bottomSheet: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Say: "player 1 start" • "2 lap" • "player 3 stop"',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
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

          SafeArea(
            child: GestureDetector(
              onTap: _toggleListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: _isListening ? Colors.redAccent : const Color(0xFF007BFF),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isListening ? Icons.mic : Icons.mic_off,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isListening ? "Listening... Tap to stop" : "Tap to Speak",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        player.showLaps = !player.showLaps;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007BFF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${player.laps.length} lap${player.laps.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF007BFF),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            player.showLaps ? Icons.expand_less : Icons.expand_more,
                            color: const Color(0xFF007BFF),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
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

            // Expandable lap list
            if (player.showLaps && player.laps.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              ...List.generate(player.laps.length, (index) {
                final lapTime = player.laps[index];
                final lapDuration = index == 0
                    ? lapTime
                    : Duration(
                    milliseconds: lapTime.inMilliseconds - player.laps[index - 1].inMilliseconds);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF007BFF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total: ${_formatTime(lapTime)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'monospace',
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
                      ),
                    ],
                  ),
                );
              }),
            ],
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
              const PopupMenuItem(
                value: SortFilter.lowToHigh,
                child: Text('Player # Low to High'),
              ),
              const PopupMenuItem(
                value: SortFilter.highToLow,
                child: Text('Player # High to Low'),
              ),
              const PopupMenuItem(
                value: SortFilter.fastestTime,
                child: Text('Fastest Time'),
              ),
              const PopupMenuItem(
                value: SortFilter.mostLaps,
                child: Text('Most Laps'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              children: [
                Icon(Icons.emoji_events, size: 64, color: Colors.amber),
                SizedBox(height: 12),
                Text(
                  '🏆 Leaderboard 🏆',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Ask: "Compare player 1 and player 2" or "Show player 3 laps"',
                  style: TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          if (_lastRecognizedCommand.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF007BFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF007BFF).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Heard:',
                    style: TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _lastRecognizedCommand,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF007BFF), fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: sortedPlayers.length,
              itemBuilder: (context, index) {
                final player = sortedPlayers[index];
                return _buildSummaryPlayerCard(player, index);
              },
            ),
          ),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ),

              SafeArea(
                child: GestureDetector(
                  onTap: _toggleListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    color: _isListening ? Colors.redAccent : const Color(0xFF007BFF),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isListening ? Icons.mic : Icons.mic_off,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isListening ? "Listening... Tap to stop" : "Tap to Ask Questions",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPlayerCard(PlayerStopwatch player, int rank) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: rank == 0
                  ? Colors.amber
                  : rank == 1
                  ? Colors.grey
                  : rank == 2
                  ? const Color(0xFFCD7F32)
                  : const Color(0xFF007BFF),
              child: Text(
                '${rank + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              'Player ${player.playerNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              'Time: ${_formatTime(player.finalTime)} • Laps: ${player.laps.length}',
              style: const TextStyle(fontSize: 14),
            ),
            trailing: player.laps.isNotEmpty
                ? IconButton(
              icon: Icon(
                player.showLaps ? Icons.expand_less : Icons.expand_more,
                color: const Color(0xFF007BFF),
              ),
              onPressed: () {
                setState(() {
                  player.showLaps = !player.showLaps;
                });
              },
            )
                : null,
          ),
          // Expandable lap details
          if (player.showLaps && player.laps.isNotEmpty) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Lap Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF007BFF),
                      ),
                    ),
                  ),
                  ...List.generate(player.laps.length, (index) {
                    final lapTime = player.laps[index];
                    final lapDuration = index == 0
                        ? lapTime
                        : Duration(
                        milliseconds: lapTime.inMilliseconds -
                            player.laps[index - 1].inMilliseconds);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF007BFF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total: ${_formatTime(lapTime)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'monospace',
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
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final centiseconds = (duration.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds:$centiseconds';
  }
}

// Small pair class to return (index, duration)
class _ItemPair {
  final int item1;
  final Duration item2;
  _ItemPair(this.item1, this.item2);
}

class PlayerStopwatch {
  final int playerNumber;
  late Ticker _ticker;
  final Stopwatch _stopwatch = Stopwatch();
  final List<Duration> laps = [];
  bool isRunning = false;
  Duration finalTime = Duration.zero;

  // show/hide laps in UI
  bool showLaps = false;

  final _elapsedController = StreamController<Duration>.broadcast();
  Stream<Duration> get elapsedStream => _elapsedController.stream;

  PlayerStopwatch({required this.playerNumber, required TickerProvider vsync}) {
    _ticker = vsync.createTicker(_onTick);
  }

  void _onTick(Duration elapsed) {
    _elapsedController.add(_stopwatch.elapsed);
  }

  void start() {
    if (!isRunning) {
      _stopwatch.start();
      _ticker.start();
      isRunning = true;
    }
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
  }
}