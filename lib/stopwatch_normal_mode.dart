import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import 'widgets/global_scaffold.dart';

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

  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  List<Duration> _laps = [];
  Duration _lastAnnouncedTime = Duration.zero;
  bool _showSummary = false;

  // Voice control states
  bool _isListening = false;
  bool _isReadingLapSummary = false;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _elapsed = Duration.zero;
    _ticker = createTicker(_onTick);
    _initTts();
    _initSpeech();

    // Auto-start if coming from homepage
    if (widget.autoStart) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _start();
        }
      });
    }
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
  }

  Future<void> _initSpeech() async {
    try {
      await _speech.initialize(
        onStatus: (status) {
          debugPrint('🎙 Speech status: $status');
          if (status == 'done' || status == 'notListening') {
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
    } catch (e) {
      debugPrint('❌ Speech init error: $e');
    }
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
    if (_isReadingLapSummary) return; // Don't interrupt lap summary

    final minutes = _elapsed.inMinutes;
    final seconds = _elapsed.inSeconds.remainder(60);
    String announcement = minutes > 0
        ? "$minutes minute${minutes != 1 ? 's' : ''} $seconds second${seconds != 1 ? 's' : ''}"
        : "$seconds second${seconds != 1 ? 's' : ''}";
    await _tts.speak(announcement);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _stopwatch.stop();
    _tts.stop();
    _speech.stop();
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
    }
  }

  // ==================== VOICE CONTROL ====================

  Future<void> _startListening() async {
    if (!await _speech.hasPermission) {
      await _speech.initialize();
    }

    if (!mounted || _isListening) return;

    setState(() => _isListening = true);

    await _speech.listen(
      listenMode: stt.ListenMode.confirmation,
      partialResults: false,
      localeId: 'en_US',
      onResult: (result) async {
        if (!mounted) return;

        final words = result.recognizedWords.toLowerCase().trim();
        if (words.isEmpty) return;

        debugPrint('🗣 Recognized: $words');

        if (result.finalResult) {
          await _handleVoiceCommand(words);
          await _stopListening();
        }
      },
    );
  }

  Future<void> _stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {}
    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  Future<void> _handleVoiceCommand(String command) async {
    // Stop reading lap summary if active
    if (_isReadingLapSummary && (command.contains('skip') ||
        command.contains('stop') ||
        command.contains('close'))) {
      await _stopReadingLapSummary();
      return;
    }

    if (command.contains('start')) {
      _start();
      await _tts.speak('Stopwatch started');
    }
    else if (command.contains('stop') || command.contains('pause')) {
      _stop();
      await _tts.speak('Stopwatch stopped');
    }
    else if (command.contains('reset')) {
      _reset();
      await _tts.speak('Stopwatch reset');
    }
    else if (command.contains('lap')) {
      if (command.contains('summary')) {
        await _readLapSummary();
      } else {
        _lap();
        await _tts.speak('Lap ${_laps.length} recorded');
      }
    }
    else if (command.contains('summary')) {
      await _readLapSummary();
    }
    else {
      await _tts.speak('Sorry, I didn\'t understand that command');
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
        // Stop reading when user exits
        if (_isReadingLapSummary) {
          await _stopReadingLapSummary();
        }
        _tts.stop();
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
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: _laps.isNotEmpty
                        ? () => setState(() => _showSummary = true)
                        : null,
                    icon: const Icon(Icons.list_alt),
                    label: Text(
                        _laps.isEmpty ? 'No Laps Yet' : 'View ${_laps.length} Laps'),
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
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
        bottomSheet: SafeArea(
          child: GestureDetector(
            onLongPress: _startListening,
            onLongPressEnd: (_) => _stopListening(),
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
                    _isListening
                        ? "Listening... Release to stop"
                        : "Hold to Speak",
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
          leading: BackButton(
            color: Colors.black,
            onPressed: () async {
              if (_isReadingLapSummary) {
                await _stopReadingLapSummary();
              }
              setState(() => _showSummary = false);
            },
          ),
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
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Time: ${_formatTime(_elapsed)}',
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
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
                      milliseconds:
                      lapTime.inMilliseconds - _laps[index - 1].inMilliseconds);
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
                        child: Text('$lapNumber',
                            style: const TextStyle(color: Colors.white, fontSize: 18)),
                      ),
                      title: Text(
                        'Total: ${_formatTime(lapTime)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                      ),
                      subtitle: Text(
                        'Split: ${_formatTime(lapDuration)}',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black54, fontFamily: 'monospace'),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
        bottomSheet: SafeArea(
          child: GestureDetector(
            onLongPress: _startListening,
            onLongPressEnd: (_) => _stopListening(),
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
                    _isListening
                        ? "Listening... Release to stop"
                        : "Hold to Speak",
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}