import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/content_view.dart';
import 'services/timer_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  TimerService.instance.init();

  runApp(
    const ProviderScope(
      child: SatoriApp(),
    ),
  );
}

class SatoriApp extends StatelessWidget {
  const SatoriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Satori',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1C1C1E),
        useMaterial3: true,
      ),
      home: const ContentView(),
    );
  }
}
