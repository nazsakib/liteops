import 'package:flutter/material.dart';
import 'app_navigation.dart';

void main() {
  runApp(const LiteOpsApp());
}

class LiteOpsApp extends StatelessWidget {
  const LiteOpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LiteOps',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          primary: Colors.black,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
      // --- UPDATED HOME ---
      home: const AppInitializationWrapper(),
    );
  }
}

// --- NEW STATEFUL WRAPPER FOR STARTUP LOGIC ---
class AppInitializationWrapper extends StatefulWidget {
  const AppInitializationWrapper({super.key});

  @override
  State<AppInitializationWrapper> createState() => _AppInitializationWrapperState();
}

class _AppInitializationWrapperState extends State<AppInitializationWrapper> {
  @override
  void initState() {
    super.initState();
    // Logic removed from here because AppNavigation now handles 
    // the silent update check and the red notification dot.
  }

  @override
  Widget build(BuildContext context) {
    // Keeps your existing navigation structure
    return const AppNavigation();
  }
}