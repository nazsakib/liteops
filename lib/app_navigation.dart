import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart'; 
import 'package:url_launcher/url_launcher.dart';       
import 'inventory_form.dart';
import 'invoice_form.dart';
import 'update_service.dart'; 
import 'dashboard_screen.dart'; // Correctly imported dashboard_screen.dart

class AppNavigation extends StatefulWidget {
  const AppNavigation({super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  // --- NEW STATE VARIABLES ---
  UpdateInfo? _updateInfo;
  String _currentFullVersion = "Checking...";

  @override
  void initState() {
    super.initState();
    _initVersionCheck();
  }

  Future<void> _initVersionCheck() async {
    final info = await UpdateService.getUpdateInfo();
    final package = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _updateInfo = info;
        _currentFullVersion = "${package.version}+${package.buildNumber}";
      });
    }
  }

  void _showAppDetails() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("LiteOps", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Smart Inventory & Business Intelligence System", style: TextStyle(color: Colors.grey)),
            const Text("Developed by Sakib MD Nazmush", 
              style: TextStyle(fontSize: 10, color: Colors.blueGrey), textAlign: TextAlign.center),
            const Divider(height: 30),
            
            Text("Installed Version: v$_currentFullVersion", style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 15),

            if (_updateInfo?.hasUpdate ?? false) ...[
              const Text("A new version is available!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => launchUrl(Uri.parse(_updateInfo!.downloadUrl), mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.download),
                label: Text("Update to v${_updateInfo?.latestBuild}"),
              ),
            ] else
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text("App is up to date", style: TextStyle(color: Colors.blueGrey)),
                ],
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- UPDATED BODY: DIRECTLY LOADS DASHBOARD ---
      body: const BusinessDashboard(),
      
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        mini: true,
        onPressed: _showAppDetails,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.info_outline, color: Colors.black),
            if (_updateInfo?.hasUpdate ?? false)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
      // --- NAVIGATION BAR REMOVED ---
    );
  }
}