import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

class StopwatchNormalMode extends StatefulWidget {
  final bool autoStart;

  const StopwatchNormalMode({super.key, this.autoStart = false});

  @override
  State<StopwatchNormalMode> createState() => _StopwatchNormalModeState();
}

class _StopwatchNormalModeState extends State<StopwatchNormalMode>
    with TickerProviderStateMixin {
  late Stopwatch _stopwatch;
  late Duration _elapsed;
  late Ticker _ticker;
  bool _isRunning = false;

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false;
  String _lastRecognizedCommand = '';

  List<Duration> _laps = [];
  Duration _lastAnnouncedTime = Duration.zero;
  bool _showSummary = false;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _elapsed = Duration.zero;
    _ticker = createTicker(_onTick);
    _initSpeech();
    _initTts();

    // Auto-start if coming from homepage voice command
    if (widget.autoStart) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _start();
          _startListening(); // Auto-start voice listening
        }
      });
    }
  }

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        print('🎙️ Speech status: $status');
        if (status == 'notListening' && mounted && !_showSummary && _isListening) {
          // Auto-restart listening if it stops while user wants it on
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && _isListening && !_showSummary) {
              _startListening();
            }
          });
        }
      },
      onError: (error) {
        print('⚠️ Speech error: $error');
      },
    );

    if (available) {
      print('✅ Speech initialized successfully');
    } else {
      print('❌ Speech recognition not available');
    }
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.3);
    await _tts.setPitch(1.0);
  }

  void _onTick(Duration duration) {
    if (mounted) {
      setState(() {
        _elapsed = _stopwatch.elapsed;
      });
      _checkTimeAnnouncement();
    }
  }

  void _checkTimeAnnouncement() {
    final currentSeconds = _elapsed.inSeconds;
    final lastAnnouncedSeconds = _lastAnnouncedTime.inSeconds;

    if (currentSeconds > 0 &&
        currentSeconds % 30 == 0 &&
        currentSeconds != lastAnnouncedSeconds) {
      _lastAnnouncedTime = _elapsed;
      _announceTime();
    }
  }

  Future<void> _announceTime() async {
    final minutes = _elapsed.inMinutes;
    final seconds = _elapsed.inSeconds.remainder(60);

    String announcement;
    if (minutes > 0) {
      announcement = "$minutes minute${minutes != 1 ? 's' : ''} $seconds second${seconds != 1 ? 's' : ''}";
    } else {
      announcement = "$seconds second${seconds != 1 ? 's' : ''}";
    }

    await _tts.speak(announcement);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _stopwatch.stop();
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }

  void _start() {
    if (!_isRunning) {
      _stopwatch.start();
      _ticker.start();
      setState(() => _isRunning = true);
    }
  }

  void _stop() {
    if (_isRunning) {
      _stopwatch.stop();
      _ticker.stop();
      setState(() => _isRunning = false);
    }
  }

  void _reset() {
    _stopwatch.reset();
    _laps.clear();
    _lastAnnouncedTime = Duration.zero;
    setState(() {
      _elapsed = Duration.zero;
      _isRunning = false;
    });
    _ticker.stop();
  }

  void _lap() {
    if (_isRunning) {
      setState(() {
        _laps.add(_elapsed);
      });
      print('✅ Lap ${_laps.length} recorded: ${_formatTime(_elapsed)}');
    }
  }

  // ✅ REMOVED: _toggleListening() - no longer needed

  Future<void> _startListening() async {
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
              print('✅ Final command: "$words"');
              setState(() {
                _lastRecognizedCommand = words;
              });
              _handleVoiceCommand(words);
            } else if (words.isNotEmpty) {
              setState(() {
                _lastRecognizedCommand = '$words...';
              });
            }
          },
          listenFor: const Duration(minutes: 10),
          pauseFor: const Duration(seconds: 2),
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.confirmation,
        );
      } catch (e) {
        print('❌ Listen error: $e');
        setState(() => _isListening = false);
      }
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
      _lastRecognizedCommand = '';
    });
  }

  Future<void> _handleVoiceCommand(String command) async {
    print('🎯 Processing: "$command"');

    if (command.contains('reset')) {
      _reset();
      _speakFast('Reset');
      print('✅ RESET executed');
    }
    else if (command.contains('lap')) {
      if (_isRunning) {
        _lap();
        _speakFast('Lap ${_laps.length}');
        print('✅ LAP executed - Total laps: ${_laps.length}');
      } else {
        _speakFast('Start timer first');
        print('⚠️ Cannot LAP - not running');
      }
    }
    else if (command.contains('stop') || command.contains('pause')) {
      if (_isRunning) {
        _stop();
        _speakFast('Stopped');
        print('✅ STOP executed');
      } else {
        print('⚠️ Already stopped');
      }
    }
    else if (command.contains('start')) {
      if (!_isRunning) {
        _start();
        _speakFast('Started');
        print('✅ START executed');
      } else {
        print('⚠️ Already running');
      }
    }
    else if (command.contains('summary') || command.contains('show laps')) {
      if (_laps.isNotEmpty) {
        setState(() => _showSummary = true);
        _speakFast('Showing laps');
        await _stopListening();
      } else {
        _speakFast('No laps recorded');
      }
    }
    else {
      print('❌ Unknown command');
    }
  }

  Future<void> _speakFast(String text) async {
    try {
      await _tts.stop();
      await _tts.setSpeechRate(1.3);
      await _tts.speak(text);
    } catch (e) {
      print("TTS error: $e");
    }
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final centiseconds =
    (duration.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds:$centiseconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_showSummary) {
      return _buildSummaryScreen();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Normal Mode', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(
          color: Colors.black,
          onPressed: () {
            _tts.stop();
            _speech.cancel();
            Navigator.of(context).pop();
          },
        ),
        // ✅ REMOVED: Local mic button from AppBar actions
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Timer Display
                Text(
                  _formatTime(_elapsed),
                  style: const TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 40),

                // Control Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildControlButton(
                      label: 'Lap',
                      icon: Icons.flag,
                      onPressed: _isRunning ? _lap : null,
                      color: const Color(0xFF007BFF),
                    ),
                    const SizedBox(width: 16),
                    _buildControlButton(
                      label: _isRunning ? 'Stop' : 'Start',
                      icon: _isRunning ? Icons.pause : Icons.play_arrow,
                      onPressed: _isRunning ? _stop : _start,
                      color: _isRunning ? Colors.orange : Colors.green,
                    ),
                    const SizedBox(width: 16),
                    _buildControlButton(
                      label: 'Reset',
                      icon: Icons.refresh,
                      onPressed: _reset,
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (_laps.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _showSummary = true);
                      _stopListening();
                    },
                    icon: const Icon(Icons.list_alt, size: 20),
                    label: Text('View ${_laps.length} Lap${_laps.length > 1 ? 's' : ''}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007BFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                const SizedBox(height: 32),

                // ✅ NEW: Replaced local mic button with global mic hint
                Column(
                  children: [
                    Semantics(
                      label: 'Voice control info',
                      hint: 'Use the mic bar at the bottom of the screen',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: _isListening
                              ? Colors.red.withOpacity(0.1)
                              : const Color(0xFF007BFF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isListening
                                ? Colors.red.withOpacity(0.3)
                                : const Color(0xFF007BFF).withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              color: _isListening ? Colors.red : const Color(0xFF007BFF),
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _isListening
                                  ? '🎤 Listening for commands...'
                                  : 'Tap mic bar below to enable voice',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _isListening ? Colors.red : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Say: "start" • "stop" • "lap" • "reset"',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            if (_lastRecognizedCommand.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Heard:',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _lastRecognizedCommand,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF007BFF),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      // ✅ NEW: Add bottom mic bar directly in this page
      bottomNavigationBar: GestureDetector(
        onTap: () async {
          if (_isListening) {
            await _stopListening();
          } else {
            await _startListening();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: _isListening ? Colors.redAccent : const Color(0xFF007BFF),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: SafeArea(
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
    );
  }

  Widget _buildSummaryScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Lap Summary', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Icon(Icons.flag, size: 64, color: Color(0xFF007BFF)),
                const SizedBox(height: 12),
                Text(
                  '${_laps.length} Lap${_laps.length > 1 ? 's' : ''} Recorded',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Time: ${_formatTime(_elapsed)}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _speakSummary,
                  icon: const Icon(Icons.volume_up, size: 24),
                  label: const Text(
                    'Speak Summary Aloud',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _laps.length,
              itemBuilder: (context, index) {
                final lapNumber = index + 1;
                final lapTime = _laps[index];
                final lapDuration = index == 0
                    ? lapTime
                    : Duration(
                    milliseconds: lapTime.inMilliseconds - _laps[index - 1].inMilliseconds);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF007BFF),
                      child: Text(
                        '$lapNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      'Total: ${_formatTime(lapTime)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                    subtitle: Text(
                      'Split: ${_formatTime(lapDuration)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontFamily: 'monospace',
                      ),
                    ),
                    trailing: const Icon(Icons.flag, color: Color(0xFF007BFF)),
                  ),
                );
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
                  onPressed: () async {
                    await _tts.stop();
                    setState(() => _showSummary = false);
                    if (_isListening) {
                      _startListening();
                    }
                  },
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

  Future<void> _speakSummary() async {
    if (_laps.isEmpty) {
      await _tts.speak("No laps recorded");
      return;
    }

    String summary = "Lap summary. Total time: ${_formatTimeSpoken(_elapsed)}. ";
    summary += "You completed ${_laps.length} lap${_laps.length > 1 ? 's' : ''}. ";

    for (int i = 0; i < _laps.length; i++) {
      final lapNumber = i + 1;
      final lapTime = _laps[i];
      final lapDuration = i == 0
          ? lapTime
          : Duration(milliseconds: lapTime.inMilliseconds - _laps[i - 1].inMilliseconds);

      summary += "Lap $lapNumber: split time ${_formatTimeSpoken(lapDuration)}, total ${_formatTimeSpoken(lapTime)}. ";
    }

    await _tts.setSpeechRate(0.9);
    await _tts.speak(summary);
  }

  String _formatTimeSpoken(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    final centiseconds = (duration.inMilliseconds.remainder(1000) ~/ 10);

    if (minutes > 0) {
      return "$minutes minute${minutes != 1 ? 's' : ''} $seconds second${seconds != 1 ? 's' : ''} and $centiseconds centiseconds";
    } else if (seconds > 0) {
      return "$seconds second${seconds != 1 ? 's' : ''} and $centiseconds centiseconds";
    } else {
      return "$centiseconds centiseconds";
    }
  }

  Widget _buildControlButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        disabledBackgroundColor: Colors.grey.shade300,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}