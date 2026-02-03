import 'package:flutter/material.dart';
import 'app_navigation.dart';
// Ensure you import your dashboard file here
// import 'dashboard_screen.dart'; 

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
        // Using a clean, professional palette for AREEJA
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          primary: Colors.black,
          surface: const Color(0xFFF8F9FB), // Subtle grey background for modern look
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
      // --- UPDATED HOME TO SHOW DASHBOARD FIRST ---
      home: const AppNavigation(), 
    );
  }
}

class AppInitializationWrapper extends StatefulWidget {
  const AppInitializationWrapper({super.key});

  @override
  State<AppInitializationWrapper> createState() => _AppInitializationWrapperState();
}

class _AppInitializationWrapperState extends State<AppInitializationWrapper> {
  @override
  Widget build(BuildContext context) {
    // This wrapper remains as a clean entry point into your Navigation shell
    return const AppNavigation();
  }
}