import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/logic/tutorial/tutorial_controller.dart';

// ---------------------------------------------------------
// 1. MOCK METHOD CHANNEL FOR FLUTTER_TTS (no code change!)
// ---------------------------------------------------------

const MethodChannel ttsChannel = MethodChannel('flutter_tts');

void mockTts() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(ttsChannel, (call) async {
    // Ignore all TTS calls, return success.
    return 1;
  });
}

// ---------------------------------------------------------
// Helper widget to provide BuildContext inside a test
// ---------------------------------------------------------

class TestContextHolder extends StatelessWidget {
  final void Function(BuildContext) onBuild;
  const TestContextHolder({required this.onBuild});

  @override
  Widget build(BuildContext context) {
    onBuild(context);
    return const SizedBox.shrink();
  }
}

void main() {
  setUp(() {
    mockTts(); // ensures TTS never touches the real device layer
  });

  // ---------------------------------------------------------
  // TEST 1 — start()
  // ---------------------------------------------------------
  testWidgets("start() initializes tutorial correctly", (tester) async {
    late BuildContext ctx;
    final tabs = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: TestContextHolder(onBuild: (c) => ctx = c),
      ),
    );

    final controller = TutorialController(
      context: ctx,
      goToTab: (i) => tabs.add(i),
      pushPage: (_) async {},
    );

    // act
    controller.start();

    // ✅ Check immediate state right after start()
    expect(controller.isActive, true);
    expect(controller.isPaused, false);
    expect(controller.step, 0);

    // ✅ Now let the entire tutorial run so no timers are left pending
    await tester.pump(const Duration(seconds: 7));

    // Optional: assert that the full flow happened
    expect(controller.isActive, false);        // finished
    expect(tabs, equals([1, 3, 3, 0]));        // steps 0,1,2,finish
  });

  // ---------------------------------------------------------
  // TEST 2 — pause()
  // ---------------------------------------------------------
  testWidgets("pause() pauses tutorial", (tester) async {
    late BuildContext ctx;

    await tester.pumpWidget(
      MaterialApp(
        home: TestContextHolder(onBuild: (c) => ctx = c),
      ),
    );

    final controller = TutorialController(
      context: ctx,
      goToTab: (_) {},
      pushPage: (_) async {},
    );

    controller.start();

    // Let it start running _runCurrentStep (but not finish delay)
    await tester.pump(const Duration(milliseconds: 100));

    // Act: pause the tutorial
    controller.pause();

    // ✅ IMPORTANT: let the pending 1s timer complete
    await tester.pump(const Duration(seconds: 2));

    // Now there are no pending timers and the test can safely end

    // Assertions
    expect(controller.isPaused, true);
    expect(controller.isActive, true); // still active but paused
  });


  // ---------------------------------------------------------
  // TEST 3 — stop()
  // ---------------------------------------------------------
  testWidgets("stop() deactivates tutorial", (tester) async {
    late BuildContext ctx;

    await tester.pumpWidget(
      MaterialApp(
        home: TestContextHolder(onBuild: (c) => ctx = c),
      ),
    );

    final controller = TutorialController(
      context: ctx,
      goToTab: (_) {},
      pushPage: (_) async {},
    );

    controller.start();

    // Let it schedule the first Future.delayed
    await tester.pump(const Duration(milliseconds: 100));

    // Act: stop the tutorial
    controller.stop();

    // 🔴 This is what you were missing:
    // Let the pending 1s timer complete so there are NO pending timers.
    await tester.pump(const Duration(seconds: 2));

    // Now assert
    expect(controller.isActive, false);
    expect(controller.isPaused, false);
  });

  // ---------------------------------------------------------
  // TEST 4 — full tutorial sequence (steps 0 → 1 → 2 → finish)
  // ---------------------------------------------------------
  testWidgets("Tutorial runs through all steps correctly", (tester) async {
    late BuildContext ctx;
    final tabs = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: TestContextHolder(onBuild: (c) => ctx = c),
      ),
    );

    final controller = TutorialController(
      context: ctx,
      goToTab: (i) => tabs.add(i),
      pushPage: (_) async {},
    );

    controller.start();

    // Allow enough time for step 0 → 1 → 2 → complete
    await tester.pump(const Duration(seconds: 7));

    expect(controller.isActive, false);
    expect(controller.isPaused, false);

    // Expected navigation order:
    // Step 0: tab 1
    // Step 1: tab 3
    // Step 2: tab 3
    // Finish: tab 0
    expect(tabs, equals([1, 3, 3, 0]));
  });
}
