import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
  // Thay đổi IP này theo máy của bạn
  // Android Emulator: 10.0.2.2
  // iOS Simulator: localhost
  // Real Device: IP máy tính của bạn (vd: 192.168.1.100)
  static const String baseUrl = 'http://10.0.2.2:5000/api';

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
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveToken(data['token']);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // GET ALL USERS
  Future<List<User>> getUsers() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // CREATE USER
  Future<Map<String, dynamic>> createUser(User user) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(user.toJson()),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // UPDATE USER
  Future<Map<String, dynamic>> updateUser(String id, User user) async {
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/users/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(user.toJson()),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // DELETE USER
  Future<Map<String, dynamic>> deleteUser(String id) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

// UPLOAD IMAGE - ĐÃ SỬA LỖI
  Future<Map<String, dynamic>> uploadImage(String userId, XFile image) async {
    try {
      final token = await _getToken();
      print('Uploading image for user: $userId');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload/$userId'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      
      // SỬA LỖI FILENAME - ĐƠN GIẢN
      request.files.add(await http.MultipartFile.fromPath(
        'image', 
        image.path,
        filename: 'user_$userId.jpg',
      ));

      print('Sending upload request...');
      var response = await request.send();
      var respStr = await response.stream.bytesToString();
      
      print('Upload Response Status: ${response.statusCode}');
      print('Upload Response Body: $respStr');

      final result = json.decode(respStr);
      
      if (response.statusCode == 200 && result['success'] == true) {
        return {
          'success': true,
          'url': result['url'],
          'publicId': result['public_id']
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Upload failed'
        };
      }
    } on FormatException catch (e) {
      print('JSON Parse Error in upload: $e');
      return {
        'success': false, 
        'message': 'Invalid response format from server'
      };
    } catch (e) {
      print('Upload Error: $e');
      return {
        'success': false, 
        'message': 'Upload failed: $e'
      };
    }
  }

  // REMOVE IMAGE
  Future<Map<String, dynamic>> removeImage(String userId, String publicId) async {
    try {
      final token = await _getToken();
      print('Removing image for user: $userId, publicId: $publicId');

      final response = await http.delete(
        Uri.parse('$baseUrl/remove/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Remove Response Status: ${response.statusCode}');
      print('Remove Response Body: ${response.body}');

      final result = json.decode(response.body);
      
      if (response.statusCode == 200 && result['success'] == true) {
        return {
          'success': true,
          'message': result['message']
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Remove failed'
        };
      }
    } on FormatException catch (e) {
      print('JSON Parse Error in remove: $e');
      return {
        'success': false,
        'message': 'Invalid response format'
      };
    } catch (e) {
      print('Remove Error: $e');
      return {
        'success': false,
        'message': 'Remove failed: $e'
      };
    }
  }
}
