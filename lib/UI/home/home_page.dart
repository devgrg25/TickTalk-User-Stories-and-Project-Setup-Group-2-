import 'dart:async';
import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../../logic/timer/timer_manager.dart';
import '../../../logic/timer/timer_controller.dart';
import '../timer/countdown_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  Timer? refreshTimer;
  StreamSubscription? sub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();

    sub = TimerManager.instance.onChange.listen((_) {
      if (mounted) setState(() {});
    });

    refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    sub?.cancel();
    refreshTimer?.cancel();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  void _openCountdown(ActiveTimer t) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CountdownPage(
          controller: t.controller,
          onExit: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timers = TimerManager.instance.timers;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              "TickTalk",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            timers.isEmpty
                ? const Expanded(
              child: Center(
                child: Text("No active timers",
                    style: TextStyle(color: Colors.grey)),
              ),
            )
                : Expanded(
              child: ListView.builder(
                itemCount: timers.length,
                itemBuilder: (_, i) {
                  final t = timers[i];
                  final current = t.controller.current;
                  final subtitleText = current == null
                      ? "Finished"
                      : "${current.name} — ${TimerController.format(t.controller.remainingSeconds)}";
                  return ListTile(
                    onTap: () => _openCountdown(t),
                    title: Text(t.name,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      subtitleText,
                      style: TextStyle(
                        color: current == null
                            ? Colors.redAccent
                            : Colors.white70,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () =>
                          TimerManager.instance.stopTimer(t.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
