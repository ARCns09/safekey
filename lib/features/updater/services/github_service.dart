import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/github_release.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GithubService {
  static const String repoUrl = 'https://api.github.com/repos/ARCns09/safekey/releases/latest';

  Future<GithubRelease?> getLatestRelease() async {
    try {
      final response = await http.get(
        Uri.parse(repoUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final release = GithubRelease.fromJson(data);
        
        // Cache last checked timestamp
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_update_check', DateTime.now().toIso8601String());
        
        return release;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<DateTime?> getLastCheckedTime() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('last_update_check');
    if (str != null) {
      return DateTime.tryParse(str);
    }
    return null;
  }
}
