import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  // Replace these with your actual GitHub username and Repo name
  static const String _baseUrl = "https://nazsakib.github.io/liteops/version.json";

  static Future<void> checkVersion(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(_baseUrl)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        int latestBuild = int.parse(data['version'].toString());

        // Get the current build number of the app on your phone
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        int currentBuild = int.parse(packageInfo.buildNumber);

        if (latestBuild > currentBuild) {
          _showUpdateDialog(context, data['url']);
        }
      }
    } catch (e) {
      debugPrint("Update Check Failed: $e");
    }
  }

  static void _showUpdateDialog(BuildContext context, String downloadUrl) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must choose an option
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.system_update_alt, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text("Update Available"),
          ],
        ),
        content: const Text(
          "A new version of LiteOps is available. Please update to ensure all features work correctly.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Maybe Later", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            onPressed: () async {
              final url = Uri.parse(downloadUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text("Update Now"),
          ),
        ],
      ),
    );
  }
}