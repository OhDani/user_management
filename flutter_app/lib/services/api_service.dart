import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000';

  // Lấy token từ SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Lưu token
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Xóa token (logout)
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // LOGIN 
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final url = Uri.parse('$baseUrl/auth/login');
      print('🔵 Login URL: $url');
      print('🔵 Body: {email: $email, password: ***}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json', 
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('🟡 Status: ${response.statusCode}');
      print('🟡 Response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveToken(data['token']);
        print('🟢 Login success, token saved');
        return {'success': true, 'data': data};
      } else {
        try {
          final error = jsonDecode(response.body);
          return {'success': false, 'message': error['message']};
        } catch (e) {
          // Nếu response là HTML (404, 500)
          return {
            'success': false,
            'message': 'Server error (${response.statusCode}): ${response.body.substring(0, 100)}'
          };
        }
      }
    } catch (e) {
      print('🔴 Login exception: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // REGISTER 
  Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    try {
      final url = Uri.parse('$baseUrl/auth/register');
      print('🔵 Register URL: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      print('🟡 Status: ${response.statusCode}');
      print('🟡 Response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        try {
          final error = jsonDecode(response.body);
          return {'success': false, 'message': error['message']};
        } catch (e) {
          return {
            'success': false,
            'message': 'Server error (${response.statusCode})'
          };
        }
      }
    } catch (e) {
      print('🔴 Register exception: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // GET ALL USERS 
  Future<List<User>> getUsers() async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/users');
      print('🔵 Get Users URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🟡 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        print('🟢 Got ${data.length} users');
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load users (${response.statusCode})');
      }
    } catch (e) {
      print('🔴 Get users exception: $e');
      throw Exception('Error: $e');
    }
  }

  // CREATE USER 
  Future<Map<String, dynamic>> createUser(User user) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/users');
      print('🔵 Create user URL: $url');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(user.toJson()),
      );

      print('🟡 Status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        try {
          final error = jsonDecode(response.body);
          return {'success': false, 'message': error['message']};
        } catch (e) {
          return {'success': false, 'message': 'Server error'};
        }
      }
    } catch (e) {
      print('🔴 Create user exception: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // UPDATE USER 
  Future<Map<String, dynamic>> updateUser(String id, User user) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/users/$id');
      print('🔵 Update user URL: $url');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(user.toJson()),
      );

      print('🟡 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        try {
          final error = jsonDecode(response.body);
          return {'success': false, 'message': error['message']};
        } catch (e) {
          return {'success': false, 'message': 'Server error'};
        }
      }
    } catch (e) {
      print('🔴 Update user exception: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // DELETE USER
  Future<Map<String, dynamic>> deleteUser(String id) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/users/$id');
      print('🔵 Delete user URL: $url');

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('🟡 Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true};
      } else {
        try {
          final error = jsonDecode(response.body);
          return {'success': false, 'message': error['message']};
        } catch (e) {
          return {'success': false, 'message': 'Server error'};
        }
      }
    } catch (e) {
      print('🔴 Delete user exception: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // UPLOAD IMAGE 
  Future<Map<String, dynamic>> uploadImage(String userId, XFile image) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/users/$userId/image');
      print('🔵 Upload image URL: $url');
      print('🔵 Image path: ${image.path}');

      var request = http.MultipartRequest('POST', url);
      
      // Thêm Authorization header
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Sửa field name từ 'image' thành 'file'
      request.files.add(
        await http.MultipartFile.fromPath('file', image.path),
      );

      print('🟡 Sending upload request...');
      var response = await request.send();
      var respStr = await response.stream.bytesToString();

      print('🟡 Status: ${response.statusCode}');
      print('🟡 Response: ${respStr.substring(0, respStr.length > 200 ? 200 : respStr.length)}');

      if (response.statusCode == 200) {
        final data = jsonDecode(respStr);
        print('🟢 Upload success');
        return {'success': true, 'data': data};
      } else {
        try {
          final data = jsonDecode(respStr);
          return {'success': false, 'message': data['message']};
        } catch (e) {
          return {
            'success': false,
            'message': 'Upload failed (${response.statusCode})'
          };
        }
      }
    } catch (e) {
      print('🔴 Upload image exception: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // PATCH USER (cập nhật một phần)
  Future<Map<String, dynamic>> patchUser(String id, Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/users/$id');
      print('🔵 Patch user URL: $url');

      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      print('🟡 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        try {
          final error = jsonDecode(response.body);
          return {'success': false, 'message': error['message']};
        } catch (e) {
          return {'success': false, 'message': 'Server error'};
        }
      }
    } catch (e) {
      print('🔴 Patch user exception: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
