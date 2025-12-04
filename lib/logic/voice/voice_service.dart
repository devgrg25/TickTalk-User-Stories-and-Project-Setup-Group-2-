import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';

import 'package:ticktalk_app/logic/timer/timer_controller.dart';
import 'package:ticktalk_app/logic/timer/timer_manager.dart';

void main() {
  // Ensure Flutter bindings are ready for method channels
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock channels used by flutter_tts and haptics (platform)
  const MethodChannel ttsChannel = MethodChannel('flutter_tts');
  const MethodChannel platformChannel = SystemChannels.platform;

  setUpAll(() {
    // Mock all flutter_tts calls to just return null
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, (MethodCall methodCall) async {
      return null; // pretend the native side handled it
    });

    // Mock platform channel (for haptics etc.) to avoid MissingPluginException
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platformChannel, (MethodCall methodCall) async {
      return null;
    });
  });

  tearDownAll(() {
    // Clean up handlers
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platformChannel, null);
  });

  group('TimerController', () {
    test('throws when created with empty intervals', () {
      expect(
            () => TimerController(intervals: const []),
        throwsA(isA<Exception>()),
      );
    });

    test('sets current, next and remainingSeconds correctly in constructor', () {
      final controller = TimerController(
        intervals: const [
          TimerInterval(name: 'First', seconds: 30),
          TimerInterval(name: 'Second', seconds: 10),
        ],
      );

      expect(controller.current, isNotNull);
      expect(controller.current!.name, 'First');
      expect(controller.remainingSeconds, 30);

      expect(controller.next, isNotNull);
      expect(controller.next!.name, 'Second');
    });

    test('format() returns mm:ss strings', () {
      expect(TimerController.format(0), '00:00');
      expect(TimerController.format(5), '00:05');
      expect(TimerController.format(65), '01:05');
      expect(TimerController.format(600), '10:00');
    });

    test('addTime() adjusts remainingSeconds and clamps at 0', () {
      final controller = TimerController(
        intervals: const [
          TimerInterval(name: 'Test', seconds: 10),
        ],
      );

      expect(controller.remainingSeconds, 10);

      controller.addTime(5);
      expect(controller.remainingSeconds, 15);

      controller.addTime(-1000);
      expect(controller.remainingSeconds, 0);
    });

    test('start() counts down and moves through intervals', () {
      fakeAsync((async) {
        int intervalCompleted = 0;
        bool timerCompleted = false;

        final controller = TimerController(
          intervals: const [
            TimerInterval(name: 'A', seconds: 2),
            TimerInterval(name: 'B', seconds: 2),
          ],
        );

        controller.onIntervalComplete = () {
          intervalCompleted++;
        };
        controller.onTimerComplete = () {
          timerCompleted = true;
        };

        controller.start();

        // Immediately after start
        expect(controller.remainingSeconds, 2);
        expect(controller.isRunning, true);

        // After 2 seconds -> first interval finished, second started
        async.elapse(const Duration(seconds: 2));
        expect(intervalCompleted, 1);
        expect(controller.current!.name, 'B');
        expect(controller.remainingSeconds, 2);
        expect(controller.isRunning, true);

        // After 2 more seconds -> timer should complete
        async.elapse(const Duration(seconds: 2));
        expect(intervalCompleted, 2);
        expect(timerCompleted, true);
        expect(controller.isStopped, true);
      });
    });

    test('pause() and resume() control countdown', () {
      fakeAsync((async) {
        final controller = TimerController(
          intervals: const [
            TimerInterval(name: 'Only', seconds: 5),
          ],
        );

        controller.start();
        expect(controller.remainingSeconds, 5);

        // 2 seconds pass
        async.elapse(const Duration(seconds: 2));
        expect(controller.remainingSeconds, 3);

        // Pause and wait 3 seconds - value should stay the same
        controller.pause();
        async.elapse(const Duration(seconds: 3));
        expect(controller.remainingSeconds, 3);

        // Resume and wait 3 seconds - it should finish
        controller.resume();
        async.elapse(const Duration(seconds: 3));
        expect(controller.remainingSeconds, 0);
        expect(controller.isStopped, true);
      });
    });

    test('stop() cancels ticker and prevents further countdown', () {
      fakeAsync((async) {
        final controller = TimerController(
          intervals: const [
            TimerInterval(name: 'StopTest', seconds: 10),
          ],
        );

        controller.start();
        expect(controller.isRunning, true);

        async.elapse(const Duration(seconds: 3));
        final valueBeforeStop = controller.remainingSeconds;

        controller.stop();
        expect(controller.isStopped, true);

        // Time passes but remainingSeconds should not change
        async.elapse(const Duration(seconds: 5));
        expect(controller.remainingSeconds, valueBeforeStop);
      });
    });
  });

  group('TimerManager', () {
    tearDown(() {
      // Clear any timers after each test
      TimerManager.instance.stopAll();
    });

    test('startTimer() adds a timer and starts it', () {
      fakeAsync((async) {
        final manager = TimerManager.instance;
        int changeCount = 0;

        final sub = manager.onChange.listen((_) {
          changeCount++;
        });

        final controller = manager.startTimer(
          'MyTimer',
          const [
            TimerInterval(name: 'Step', seconds: 2),
          ],
        );

        expect(manager.timers.length, 1);
        expect(manager.timers.first.name, 'MyTimer');
        expect(manager.timers.first.controller, same(controller));
        expect(changeCount, greaterThanOrEqualTo(1));

        // Let it finish
        async.elapse(const Duration(seconds: 2));
        expect(controller.isStopped, true);

        sub.cancel();
      });
    });

    test('stopTimer() removes the timer', () {
      final manager = TimerManager.instance;

      final controller = manager.startTimer(
        'ToRemove',
        const [
          TimerInterval(name: 'X', seconds: 5),
        ],
      );
      expect(manager.timers.length, 1);
      final id = manager.timers.first.id;
      expect(controller.isStopped, false);

      int changeCount = 0;
      final sub = manager.onChange.listen((_) {
        changeCount++;
      });

      manager.stopTimer(id);

      expect(manager.timers, isEmpty);
      expect(changeCount, greaterThanOrEqualTo(1));

      sub.cancel();
    });

    test('stopAll() stops and clears all timers', () {
      final manager = TimerManager.instance;

      manager.startTimer(
        'T1',
        const [TimerInterval(name: 'A', seconds: 5)],
      );
      manager.startTimer(
        'T2',
        const [TimerInterval(name: 'B', seconds: 5)],
      );

      expect(manager.timers.length, 2);

      int changeCount = 0;
      final sub = manager.onChange.listen((_) {
        changeCount++;
      });

      manager.stopAll();

      expect(manager.timers.length, 0);
      expect(changeCount, greaterThanOrEqualTo(1));

      sub.cancel();
    });
  });
}
