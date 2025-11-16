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
  bool _isReadingLapSummary = false;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _elapsed = Duration.zero;
    _ticker = createTicker(_onTick);
    _initSpeech();
    _initTts();

    if (widget.autoStart) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _start();
        }
      });
    }
  }

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        debugPrint('🎙️ Speech status: $status');
        if (status == 'notListening' && mounted && !_showSummary) {
          if (mounted) {
            setState(() => _isListening = false);
          }
        }
      },
      onError: (error) {
        debugPrint('⚠️ Speech error: $error');
        if (mounted) {
          setState(() => _isListening = false);
        }
      },
    );

    if (available) {
      debugPrint('✅ Speech initialized successfully');
    } else {
      debugPrint('❌ Speech recognition not available');
    }
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
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
    if (_isReadingLapSummary) return;

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
      debugPrint('✅ Lap ${_laps.length} recorded: ${_formatTime(_elapsed)}');
    }
  }

  void _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    // Stop any ongoing TTS first
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
              debugPrint('✅ Final command: "$words"');
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
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.confirmation,
        );
      } catch (e) {
        debugPrint('❌ Listen error: $e');
        setState(() => _isListening = false);
      }
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    await _tts.stop(); // Stop TTS when user taps mic again
    setState(() {
      _isListening = false;
      _lastRecognizedCommand = '';
    });
  }

  Future<void> _handleVoiceCommand(String command) async {
    debugPrint('🎯 Processing: "$command"');
    bool commandRecognized = false;

    // Stop reading lap summary
    if (_isReadingLapSummary && (command.contains('skip') ||
        command.contains('stop') ||
        command.contains('close'))) {
      await _stopReadingLapSummary();
      commandRecognized = true;
      return;
    }

    // Reset command
    if (command.contains('reset') || command.contains('clear')) {
      _reset();
      _speakFast('Reset');
      commandRecognized = true;
    }
    // Summary commands - check these BEFORE lap to avoid confusion
    else if (command.contains('summary') || command.contains('show laps') ||
        command.contains('read laps') || command.contains('list laps') ||
        command.contains('read lap') || command.contains('show lap')) {
      await _readLapSummary();
      commandRecognized = true;
    }
    // Lap commands - filter out common misrecognitions
    else if ((command.contains('lap') || command.contains('flag') || command.contains('mark')) &&
        !command.contains('black') && !command.contains('clap') && !command.contains('slap')) {
      // Regular lap command
      if (_isRunning) {
        _lap();
        _speakFast('Lap ${_laps.length}');
        commandRecognized = true;
      } else {
        _speakFast('Start stopwatch first');
        commandRecognized = true;
      }
    }
    // Stop/Pause command
    else if ((command.contains('stop') || command.contains('pause')) &&
        !command.contains('stopwatch')) {
      if (_isRunning) {
        _stop();
        _speakFast('Stopped');
        commandRecognized = true;
      } else {
        commandRecognized = true; // Don't say error if already stopped
      }
    }
    // Start command
    else if (command.contains('start') || command.contains('begin') ||
        command.contains('go') || command.contains('resume')) {
      if (!_isRunning) {
        _start();
        _speakFast('Started');
        commandRecognized = true;
      } else {
        commandRecognized = true; // Don't say error if already running
      }
    }

    // Only speak error message if command truly not recognized
    if (!commandRecognized) {
      await _tts.speak("Sorry, I didn't understand that. Try saying start, stop, lap, reset, or read laps.");
    }
  }

  Future<void> _readLapSummary() async {
    if (_laps.isEmpty) {
      await _tts.speak('No laps recorded yet');
      return;
    }

    setState(() => _isReadingLapSummary = true);

    await _tts.speak('Reading lap summary. ${_laps.length} lap${_laps.length > 1 ? 's' : ''} recorded.');

    for (int i = 0; i < _laps.length && _isReadingLapSummary; i++) {
      if (!mounted || !_isReadingLapSummary) break;

      final lapNumber = i + 1;
      final lapTime = _laps[i];
      final lapDuration = i == 0
          ? lapTime
          : Duration(
          milliseconds: lapTime.inMilliseconds - _laps[i - 1].inMilliseconds);

      final minutes = lapDuration.inMinutes;
      final seconds = lapDuration.inSeconds.remainder(60);

      String announcement = "Lap $lapNumber: ";
      if (minutes > 0) {
        announcement += "$minutes minute${minutes != 1 ? 's' : ''} and $seconds second${seconds != 1 ? 's' : ''}";
      } else {
        announcement += "$seconds second${seconds != 1 ? 's' : ''}";
      }

      await _tts.speak(announcement);
      await Future.delayed(const Duration(milliseconds: 800));
    }

    if (mounted && _isReadingLapSummary) {
      await _tts.speak('End of lap summary');
      setState(() => _isReadingLapSummary = false);
    }
  }

  Future<void> _stopReadingLapSummary() async {
    setState(() => _isReadingLapSummary = false);
    await _tts.stop();
    await _tts.speak('Lap summary stopped');
  }

  Future<void> _speakFast(String text) async {
    try {
      await _tts.stop();
      await _tts.setSpeechRate(1.3);
      await _tts.speak(text);
      await _tts.setSpeechRate(0.5);
    } catch (e) {
      debugPrint("TTS error: $e");
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

    return WillPopScope(
      onWillPop: () async {
        if (_isReadingLapSummary) {
          await _stopReadingLapSummary();
        }
        _tts.stop();
        _speech.cancel();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Normal Mode', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: BackButton(
            color: Colors.black,
            onPressed: () async {
              if (_isReadingLapSummary) {
                await _stopReadingLapSummary();
              }
              _tts.stop();
              _speech.cancel();
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Timer Display - Fixed for small screens
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _formatTime(_elapsed),
                        style: const TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Control Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _buildControlButton(
                              label: 'Lap',
                              icon: Icons.flag,
                              onPressed: _isRunning ? _lap : null,
                              color: const Color(0xFF007BFF),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildControlButton(
                              label: _isRunning ? 'Stop' : 'Start',
                              icon: _isRunning ? Icons.pause : Icons.play_arrow,
                              onPressed: _isRunning ? _stop : _start,
                              color: _isRunning ? Colors.orange : Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildControlButton(
                              label: 'Reset',
                              icon: Icons.refresh,
                              onPressed: _reset,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
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

                    if (_isReadingLapSummary) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF007BFF)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.volume_up, color: Color(0xFF007BFF)),
                            SizedBox(width: 8),
                            Text(
                              'Reading lap summary...',
                              style: TextStyle(
                                color: Color(0xFF007BFF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_lastRecognizedCommand.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007BFF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF007BFF).withOpacity(0.3),
                          ),
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

                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Say: "start" • "stop" • "lap" • "reset" • "read laps"',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomSheet: SafeArea(
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
      ),
    );
  }

  Widget _buildSummaryScreen() {
    return WillPopScope(
      onWillPop: () async {
        if (_isReadingLapSummary) {
          await _stopReadingLapSummary();
        }
        return true;
      },
      child: Scaffold(
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
                    onPressed: _readLapSummary,
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
                  if (_isReadingLapSummary) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF007BFF)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.volume_up, color: Color(0xFF007BFF)),
                          SizedBox(width: 8),
                          Text(
                            'Reading lap summary...',
                            style: TextStyle(
                              color: Color(0xFF007BFF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                      if (_isReadingLapSummary) {
                        await _stopReadingLapSummary();
                      }
                      await _tts.stop();
                      setState(() => _showSummary = false);
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
      ),
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}