import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'routines.dart';
import 'routine_timer_model.dart';
import 'voice_controller.dart';
import 'create_routine_page.dart';
import 'countdown_screenV.dart';

class RoutinesPage extends StatefulWidget {
  final PredefinedRoutines routines;
  final VoiceController voiceController;

  const RoutinesPage({
    super.key,
    required this.routines,
    required this.voiceController,
  });

  @override
  State<RoutinesPage> createState() => _RoutinesPageState();
}

class _RoutinesPageState extends State<RoutinesPage> {
  bool _isListening = false;
  List<TimerDataV> _allRoutines = [];
  static const String _customRoutinesKey = 'custom_routines_v1';
  static const String _favoritesKey = 'favorite_routine_ids_v1';

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  // --- Data Loading & Saving ---

  Future<void> _loadRoutines() async {
    final prefs = await SharedPreferences.getInstance();

    List<TimerDataV> predefined = _getPredefinedList();

    List<TimerDataV> custom = [];
    String? customJson = prefs.getString(_customRoutinesKey);
    if (customJson != null) {
      try {
        List<dynamic> decoded = jsonDecode(customJson);
        custom = decoded.map((json) => TimerDataV.fromJson(json)).toList();
      } catch (e) {
        debugPrint("Error loading custom routines: $e");
      }
    }

    Map<String, TimerDataV> routinesMap = {};
    for(var r in predefined) {
      routinesMap[r.id] = r;
    }
    for(var r in custom) {
      routinesMap[r.id] = r;
    }
    _allRoutines = routinesMap.values.toList();

    List<String> favoriteIds = prefs.getStringList(_favoritesKey) ?? [];
    for (var routine in _allRoutines) {
      if (favoriteIds.contains(routine.id)) {
        routine.isFavorite = true;
      }
    }

    setState(() {});
  }

  Future<void> _saveRoutines() async {
    final prefs = await SharedPreferences.getInstance();

    List<TimerDataV> customOnly = _allRoutines.where((r) => r.isCustom).toList();
    String customJson = jsonEncode(customOnly.map((r) => r.toJson()).toList());
    await prefs.setString(_customRoutinesKey, customJson);

    List<String> favIds = _allRoutines
        .where((r) => r.isFavorite)
        .map((r) => r.id)
        .toList();
    await prefs.setStringList(_favoritesKey, favIds);
  }

  List<TimerDataV> _getPredefinedList() {
    return [
      TimerDataV(id: 'pomodoro', name: 'Pomodoro Focus', steps: [TimerStep(name:'Work', durationInMinutes:25), TimerStep(name:'Break', durationInMinutes:5)]),
      TimerDataV(id: 'exercise', name: 'Exercise Sets', steps: [TimerStep(name:'Work', durationInMinutes:1), TimerStep(name:'Rest', durationInMinutes:1), TimerStep(name:'Work', durationInMinutes:1)]),
      TimerDataV(id: '202020', name: '20-20-20 Rule', steps: [TimerStep(name:'Focus', durationInMinutes:20), TimerStep(name:'Look Away', durationInMinutes:1)]),
      TimerDataV(id: 'mindfulness', name: 'Mindfulness Minute', steps: [TimerStep(name:'Breathe', durationInMinutes:1)]),
      TimerDataV(id: 'laundry', name: 'Laundry Cycle', steps: [TimerStep(name:'Wash', durationInMinutes:30), TimerStep(name:'Dry', durationInMinutes:45)]),
      TimerDataV(id: 'morning', name: 'Morning Routine', steps: [TimerStep(name:'Wash', durationInMinutes:5), TimerStep(name:'Dress', durationInMinutes:5), TimerStep(name:'Eat', durationInMinutes:15)]),
    ];
  }

  void _toggleFavorite(TimerDataV routine) {
    setState(() {
      routine.isFavorite = !routine.isFavorite;
    });
    _saveRoutines();
  }

  void _startRoutine(TimerDataV routine) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CountdownScreenV(timerData: routine)),
    );
  }

  void _editRoutine(TimerDataV routine) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateRoutinePage(routineToEdit: routine)),
    );

    if (result != null && result is Map) {
      final updatedRoutine = result['routine'] as TimerDataV;
      final runNow = result['runNow'] as bool;

      setState(() {
        final index = _allRoutines.indexWhere((r) => r.id == updatedRoutine.id);
        if (index != -1) {
          _allRoutines[index] = updatedRoutine;
        }
      });
      _saveRoutines();

      if (runNow) {
        _startRoutine(updatedRoutine);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${updatedRoutine.name} updated!'))
        );
      }
    }
  }

  void _deleteRoutine(TimerDataV routine) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Routine'),
          content: Text('Are you sure you want to delete "${routine.name}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                setState(() {
                  _allRoutines.removeWhere((r) => r.id == routine.id);
                });
                _saveRoutines();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${routine.name} deleted!'))
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateRoutinePage()),
    );

    if (result != null && result is Map) {
      final newRoutine = result['routine'] as TimerDataV;
      final runNow = result['runNow'] as bool;

      setState(() {
        _allRoutines.add(newRoutine);
      });
      _saveRoutines();

      if (runNow) {
        _startRoutine(newRoutine);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${newRoutine.name} created!'))
        );
      }
    }
  }

  Future<void> _startListening() async {
    if (!widget.voiceController.isInitialized) {
      await widget.voiceController.initialize();
      if (!widget.voiceController.isInitialized) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice controller not ready. Please check permissions.')),
        );
        return;
      }
    }
    setState(() => _isListening = true);
    await widget.voiceController.speak("Say the name of a routine to start.");
    await widget.voiceController.listenAndRecognize(
      onCommandRecognized: (cmd) { _handleVoiceCommand(cmd); },
      onComplete: () { if (mounted) setState(() => _isListening = false); },
    );
  }
  Future<void> _stopListening() async {
    await widget.voiceController.stopListening();
    if(mounted) setState(() => _isListening = false);
  }

  void _handleVoiceCommand(String command) {
    final normalized = command.toLowerCase().trim();
    try {
      final match = _allRoutines.firstWhere((r) => normalized.contains(r.name.toLowerCase()));
      _startRoutine(match);
    } catch (e) {
      widget.voiceController.speak("Sorry, I couldn't find that routine.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoritesList = _allRoutines.where((r) => r.isFavorite).toList();
    final customList = _allRoutines.where((r) => r.isCustom).toList();
    final standardList = _allRoutines.where((r) => !r.isCustom).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FA),
      appBar: AppBar(
        title: const Text('Routines', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToCreate,
              icon: const Icon(Icons.add_circle_outline, size: 28),
              label: const Text('Create New Routine', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007BFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 32),

          if (favoritesList.isNotEmpty) ...[
            const Text("Favorites ❤️", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: favoritesList.length,
                itemBuilder: (context, index) {
                  return _buildFavoriteCard(favoritesList[index]);
                },
              ),
            ),
            const SizedBox(height: 32),
          ],

          if (customList.isNotEmpty) ...[
            const Text("Your Created Routines", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...customList.map((routine) => _buildStandardRoutineTile(routine)).toList(),
            const SizedBox(height: 32),
          ],

          const Text("Standard Routines", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...standardList.map((routine) => _buildStandardRoutineTile(routine)).toList(),
        ],
      ),
      bottomSheet: SafeArea(
        child: GestureDetector(
          onTap: _isListening ? _stopListening : _startListening,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            color: _isListening ? Colors.redAccent : const Color(0xFF007BFF),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(TimerDataV routine) {
    return GestureDetector(
      onTap: () => _startRoutine(routine),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12, bottom: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(
                  routine.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: routine.isFavorite ? Colors.red : Colors.grey[400],
                  size: 20,
                ),
                onPressed: () => _toggleFavorite(routine),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(height: 8),
            Text(routine.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text("${routine.totalSteps} steps", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            Text("${routine.totalTime} mins", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardRoutineTile(TimerDataV routine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF007BFF).withOpacity(0.1),
          child: Icon(routine.isCustom ? Icons.person_outline : Icons.layers_outlined, color: const Color(0xFF007BFF)),
        ),
        title: Text(routine.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text("${routine.totalSteps} steps | Total: ${routine.totalTime}m"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                routine.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: routine.isFavorite ? Colors.red : Colors.grey[400],
              ),
              onPressed: () => _toggleFavorite(routine),
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Color(0xFF007BFF)),
              onPressed: () => _startRoutine(routine),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onPressed: () => _showRoutineOptions(context, routine),
            ),
          ],
        ),
        onTap: () => _startRoutine(routine),
      ),
    );
  }

  void _showRoutineOptions(BuildContext context, TimerDataV routine) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('Run Routine'),
                onTap: () {
                  Navigator.pop(bc);
                  _startRoutine(routine);
                },
              ),
              if (routine.isCustom)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Routine'),
                  onTap: () {
                    Navigator.pop(bc);
                    _editRoutine(routine);
                  },
                ),
              if (routine.isCustom)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete Routine', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(bc);
                    _deleteRoutine(routine);
                  },
                ),
              ListTile(
                leading: Icon(routine.isFavorite ? Icons.favorite : Icons.favorite_border),
                title: Text(routine.isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
                onTap: () {
                  Navigator.pop(bc);
                  _toggleFavorite(routine);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}