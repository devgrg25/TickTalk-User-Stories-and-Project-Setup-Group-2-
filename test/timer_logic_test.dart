import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';

import 'package:ticktalk_app/logic/timer/timer_controller.dart';
import 'package:ticktalk_app/logic/timer/timer_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('TimerController', () {
    test('constructor throws on empty intervals', () {
      expect(
            () => TimerController(intervals: []),
        throwsA(isA<Exception>()),
      );
    });


    test('format() converts seconds to mm:ss', () {
      expect(TimerController.format(0), '00:00');
      expect(TimerController.format(5), '00:05');
      expect(TimerController.format(65), '01:05');
      expect(TimerController.format(600), '10:00');
    });
/*
    test('addTime() adjusts remainingSeconds and clamps to >= 0', () {
      final controller = TimerController(
        intervals: [
          const TimerInterval(name: 'Test', seconds: 10),
        ],
      );

      expect(controller.remainingSeconds, 10);

      controller.addTime(5);
      expect(controller.remainingSeconds, 15);

      controller.addTime(-1000);
      expect(controller.remainingSeconds, 0);
    });*/
  /*
    test('start() counts down and moves through intervals', () {
      fakeAsync((async) {
        int intervalCompleteCount = 0;
        bool timerCompleted = false;

        final controller = TimerController(
          intervals: const [
            TimerInterval(name: 'Work', seconds: 2),
            TimerInterval(name: 'Rest', seconds: 2),
          ],
        );

        controller.onIntervalComplete = () {
          intervalCompleteCount++;
        };
        controller.onTimerComplete = () {
          timerCompleted = true;
        };

        controller.start();

        // Immediately after start
        expect(controller.remainingSeconds, 2);
        expect(controller.isRunning, true);

        // After 2 seconds, first interval should be done, second started
        async.elapse(const Duration(seconds: 2));
        expect(intervalCompleteCount, 1);
        expect(controller.current!.name, 'Rest');
        expect(controller.remainingSeconds, 2);
        expect(controller.isRunning, true);

        // After 2 more seconds, timer should complete
        async.elapse(const Duration(seconds: 2));
        expect(intervalCompleteCount, 2,
            reason: 'Both intervals should have completed');
        expect(timerCompleted, true);
        expect(controller.isStopped, true);
      });
    });*/
/*
    test('pause() and resume() stop and restart countdown', () {
      fakeAsync((async) {
        final controller = TimerController(
          intervals: const [
            TimerInterval(name: 'Work', seconds: 5),
          ],
        );

        controller.start();
        expect(controller.remainingSeconds, 5);

        // 2 seconds pass
        async.elapse(const Duration(seconds: 2));
        expect(controller.remainingSeconds, 3);

        // Pause and wait 3 seconds - should NOT change
        controller.pause();
        async.elapse(const Duration(seconds: 3));
        expect(controller.remainingSeconds, 3,
            reason: 'Remaining should not change while paused');

        // Resume and wait 3 seconds - should hit zero and complete
        controller.resume();
        async.elapse(const Duration(seconds: 3));
        expect(controller.remainingSeconds, 0);
        expect(controller.isStopped, true);
      });
    });*/

    test('stop() cancels the ticker', () {
      fakeAsync((async) {
        final controller = TimerController(
          intervals: const [
            TimerInterval(name: 'Work', seconds: 10),
          ],
        );

        controller.start();
        expect(controller.isRunning, true);

        controller.stop();
        expect(controller.isStopped, true);

        // Time passes but remainingSeconds should not decrease anymore
        final before = controller.remainingSeconds;
        async.elapse(const Duration(seconds: 5));
        expect(controller.remainingSeconds, before);
      });
    });
  });

  group('TimerManager', () {
    tearDown(() {
      // Clean up between tests
      TimerManager.instance.stopAll();
    });
/*
    test('startTimer() adds a timer and emits change', () async {
      final manager = TimerManager.instance;

      final changeFuture = expectLater(
        manager.onChange,
        emits(anything), // we only care that something was emitted
      );

      final controller = manager.startTimer(
        'My Timer',
        const [
          TimerInterval(name: 'Work', seconds: 5),
        ],
      );

      // Wait for onChange emission
      await changeFuture;

      expect(manager.timers.length, 1);
      final active = manager.timers.first;
      expect(active.name, 'My Timer');
      expect(active.controller, same(controller));
      expect(active.finished, false);
    });

    test('stopTimer() removes timer and emits change', () async {
      final manager = TimerManager.instance;

      final controller = manager.startTimer(
        'Timer to stop',
        const [
          TimerInterval(name: 'Work', seconds: 5),
        ],
      );
      final id = manager.timers.first.id;
      expect(manager.timers.length, 1);
      expect(controller.isStopped, false);

      final changeFuture = expectLater(
        manager.onChange,
        emits(anything),
      );

      manager.stopTimer(id);
      await changeFuture;

      expect(manager.timers, isEmpty);
    });*/

    test('stopAll() stops all timers and clears list', () async {
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

      final changeFuture = expectLater(
        manager.onChange,
        emits(anything),
      );

      manager.stopAll();
      await changeFuture;

      expect(manager.timers.length, 0);
    });
  });
}
