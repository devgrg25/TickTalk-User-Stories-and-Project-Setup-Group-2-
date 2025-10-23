import 'timer_model.dart';

// Typedefs are unchanged
typedef StopListeningCallback = void Function();
typedef SpeakCallback = Future<void> Function(String);
typedef PlayTimerCallback = void Function(TimerData);

class PredefinedRoutines {
  final StopListeningCallback stopListening;
  final SpeakCallback speak;
  final PlayTimerCallback playTimer;

  PredefinedRoutines({
    required this.stopListening,
    required this.speak,
    required this.playTimer,
  });

  // --- All routines now output a List<TimerStep> ---

  void startMindfulnessMinute() {
    stopListening();
    final TimerData timer = TimerData(
      id: 'predefined_mindfulness',
      name: 'Mindfulness Minute',
      steps: [
        TimerStep(name: 'Meditate', durationInMinutes: 1),
      ],
    );
    speak("Starting Mindfulness Minute.");
    playTimer(timer);
  }

  void startSimpleLaundryCycle() {
    stopListening();
    final TimerData timer = TimerData(
      id: 'predefined_laundry',
      name: 'Simple Laundry Cycle',
      steps: [
        TimerStep(name: 'Load Clothes', durationInMinutes: 2),
        TimerStep(name: 'Transfer to Dryer', durationInMinutes: 3),
      ],
    );
    speak("Starting Simple Laundry Cycle.");
    playTimer(timer);
  }

  void start202020Rule() {
    stopListening();
    final TimerData timer = TimerData(
      id: 'predefined_202020',
      name: '20-20-20 Eye Break',
      steps: [
        TimerStep(name: 'Focus', durationInMinutes: 20),
        TimerStep(name: 'Look Away', durationInMinutes: 1), // 1 min is simplest
      ],
    );
    speak("Starting 20-20-20 rule. Reminder in 20 minutes.");
    playTimer(timer);
  }

  void startPomodoroTimer() {
    stopListening();
    final TimerData timer = TimerData(
      id: 'predefined_pomodoro',
      name: 'Pomodoro Focus',
      steps: [
        TimerStep(name: 'Work', durationInMinutes: 25),
        TimerStep(name: 'Break', durationInMinutes: 5),
        TimerStep(name: 'Work', durationInMinutes: 25),
        TimerStep(name: 'Break', durationInMinutes: 5),
        TimerStep(name: 'Work', durationInMinutes: 25),
        TimerStep(name: 'Break', durationInMinutes: 5),
        TimerStep(name: 'Work', durationInMinutes: 25),
      ],
    );
    speak("Starting Pomodoro timer.");
    playTimer(timer);
  }

  void startExerciseTimer() {
    stopListening();
    final TimerData timer = TimerData(
      id: 'predefined_exercise',
      name: 'Exercise Sets',
      steps: [
        TimerStep(name: 'Work', durationInMinutes: 1),
        TimerStep(name: 'Rest', durationInMinutes: 1),
        TimerStep(name: 'Work', durationInMinutes: 1),
        TimerStep(name: 'Rest', durationInMinutes: 1),
        TimerStep(name: 'Work', durationInMinutes: 1),
        TimerStep(name: 'Rest', durationInMinutes: 1),
        TimerStep(name: 'Work', durationInMinutes: 1),
        TimerStep(name: 'Rest', durationInMinutes: 1),
        TimerStep(name: 'Work', durationInMinutes: 1),
      ],
    );
    speak("Starting Exercise Sets.");
    playTimer(timer);
  }

  // --- SEQUENTIAL TIMERS NOW WORK! ---

  void startMorningIndependence() {
    stopListening();
    final TimerData timer = TimerData(
      id: 'predefined_morning',
      name: 'Morning Independence',
      steps: [
        TimerStep(name: 'Wash', durationInMinutes: 3),
        TimerStep(name: 'Dress', durationInMinutes: 2),
        TimerStep(name: 'Eat', durationInMinutes: 5),
      ],
    );
    speak("Starting Morning Independence routine.");
    playTimer(timer);
  }

  void startRecipePrep() {
    stopListening();
    final TimerData timer = TimerData(
      id: 'predefined_recipe',
      name: 'Recipe Prep Guide',
      steps: [
        TimerStep(name: 'Chop Vegetables', durationInMinutes: 5),
        TimerStep(name: 'Marinate', durationInMinutes: 10),
        TimerStep(name: 'Preheat Oven', durationInMinutes: 3),
      ],
    );
    speak("Starting Recipe Prep guide.");
    playTimer(timer);
  }
}