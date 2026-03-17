// services/api.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

// ── Base URL config ──────────────────────────────────────────────────────────
// XAMPP on Linux — document root is /opt/lampp/htdocs/
// Place your backend folder at: /opt/lampp/htdocs/backend/
//
// Uncomment the line that matches how you are running the app:
//
//   Android emulator  → XAMPP on your machine is reachable at 10.0.2.2
//   Physical device   → Use your LAN IP (run: hostname -I | awk '{print $1}')
//   Web / Chrome      → localhost works directly
//
//const String _baseUrl = 'http://10.0.2.2/backend/';          // Android emulator
const String _baseUrl = 'http://192.168.18.5/backend/';    // Physical device — replace x
// const String _baseUrl = 'http://localhost/backend/';       // Web / Chrome
// ─────────────────────────────────────────────────────────────────────────────

/// LOGIN
Future<Map<String, dynamic>> login(String email, String pass) async {
  try {
    final res = await http
        .post(
          Uri.parse('${_baseUrl}login.php'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'email': email, 'password': pass},
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    return {'success': false, 'error': 'Server error ${res.statusCode}'};
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}

/// REGISTER
Future<Map<String, dynamic>> register(String email, String pass) async {
  try {
    final res = await http
        .post(
          Uri.parse('${_baseUrl}register.php'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'email': email, 'password': pass},
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    return {'success': false, 'error': 'Server error ${res.statusCode}'};
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}

/// CREATE ROOM  (stored as a "file" record in the backend)
/// Returns {"success": true, "code": "XXXXXX", "file_id": 42} on success.
Future<Map<String, dynamic>> createRoom(String name, int userId) async {
  try {
    final res = await http
        .post(
          Uri.parse('${_baseUrl}create_file.php'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'title':    name,
            'content':  '',
            'owner_id': userId.toString(),
          },
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    return {'success': false, 'error': 'Server error ${res.statusCode}'};
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}

/// CREATE FILE  (legacy — kept for CreateFileScreen compatibility)
Future<Map<String, dynamic>> createFile(
    String title, String content, int uid) async {
  return createRoom(title, uid);
}

/// UPLOAD FILE  (multipart)
Future<Map<String, dynamic>> uploadFile({
  required String roomCode,
  required String fileName,
  required List<int> fileBytes,
}) async {
  try {
    final uri     = Uri.parse('${_baseUrl}upload_file.php');
    final request = http.MultipartRequest('POST', uri)
      ..fields['room_code'] = roomCode
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final res      = await http.Response.fromStream(streamed);

    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    return {'success': false, 'error': 'Server error ${res.statusCode}'};
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}

/// JOIN ROOM  (looks up room by 6-char access code)
Future<Map<String, dynamic>> joinFile(String code) async {
  try {
    final res = await http
        .post(
          Uri.parse('${_baseUrl}join_file.php'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'code': code.toUpperCase()},
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    return {'success': false, 'error': 'Server error ${res.statusCode}'};
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}

/// ADMIN STATS  — user list + counts; backend re-verifies is_admin on every call
Future<Map<String, dynamic>> fetchAdminStats(int adminId) async {
  try {
    final res = await http
        .post(
          Uri.parse('${_baseUrl}admin_stats.php'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'admin_id': adminId.toString()},
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    return {'success': false, 'error': 'Server error ${res.statusCode}'};
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}