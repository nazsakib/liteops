import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final bool hasUpdate;
  final String latestBuild; // Must be 'latestBuild' to match your UI
  final String downloadUrl;

  UpdateInfo({
    required this.hasUpdate, 
    required this.latestBuild, 
    required this.downloadUrl
  });
}

class UpdateService {
  // Use your real GitHub Pages link here
  static const String _baseUrl = "https://liteops.vercel.app/version.json";

  static Future<UpdateInfo> getUpdateInfo() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl)).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // 1. Get build number from GitHub (e.g., "5")
        int githubBuildNum = int.tryParse(data['version'].toString()) ?? 0;

        // 2. Get the current app's build number from your phone (e.g., "4")
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        int localBuildNum = int.tryParse(packageInfo.buildNumber) ?? 0;

        // 3. Compare and return data using the field 'latestBuild'
        return UpdateInfo(
          hasUpdate: githubBuildNum > localBuildNum,
          latestBuild: githubBuildNum.toString(), // This goes to your button text
          downloadUrl: data['url'],
        );
      }
    } catch (e) {
      debugPrint("Update check failed: $e");
    }
    return UpdateInfo(hasUpdate: false, latestBuild: "0", downloadUrl: "");
  }
}