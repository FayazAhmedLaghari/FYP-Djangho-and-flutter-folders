// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ✅ Use the IP that works from your other project
  static const String baseUrl = 'http://192.168.43.11:8000/api/rag/';
  static const String authUrl = 'http://192.168.43.11:8000/api/auth/';
  // Get auth token with better error handling

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        print('❌ No authentication token found');
        return null;
      }

      return token;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Get refresh token
  static Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('refresh_token');
    } catch (e) {
      print('Error getting refresh token: $e');
      return null;
    }
  }

  // Save tokens
  static Future<void> saveTokens(
      String accessToken, String refreshToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', accessToken);
      await prefs.setString('refresh_token', refreshToken);
      print('💾 Tokens saved successfully');
    } catch (e) {
      print('Error saving tokens: $e');
    }
  }

  // Test connection first
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}test-public/'),
      );
      print('✅ Connection successful to: $baseUrl');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Cannot connect to $baseUrl: $e');
      return false;
    }
  }

  // Login method with connection test
  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    try {
      print('🔐 Attempting login for user: $username');
      print('🔐 Login URL: ${authUrl}token/');

      final response = await http.post(
        Uri.parse('${authUrl}token/'),
        body: {
          'username': username,
          'password': password,
        },
      ).timeout(Duration(seconds: 10));

      print('📡 Login response status: ${response.statusCode}');
      print('📡 Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveTokens(data['access'], data['refresh']);

        print('✅ Login successful! Token saved');
        return {'success': true, 'data': data};
      } else {
        // More detailed error handling
        try {
          final errorData = jsonDecode(response.body);
          final errorMsg =
              errorData['detail'] ?? 'Login failed: ${response.statusCode}';
          print('❌ Login failed: $errorMsg');
          return {'success': false, 'error': errorMsg};
        } catch (e) {
          print('❌ Login failed with status: ${response.statusCode}');
          return {
            'success': false,
            'error': 'Login failed: ${response.statusCode}'
          };
        }
      }
    } on SocketException catch (e) {
      print('❌ SocketException: $e');
      return {
        'success': false,
        'error': 'Network error: Cannot connect to authentication server'
      };
    } on TimeoutException catch (e) {
      print('❌ TimeoutException: $e');
      return {
        'success': false,
        'error': 'Login timeout: Server taking too long to respond'
      };
    } catch (e) {
      print('❌ Unexpected login error: $e');
      return {'success': false, 'error': 'Unexpected error during login: $e'};
    }
  }

  // Token refresh method with better error handling
  static Future<Map<String, dynamic>> _refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        print('❌ No refresh token available');
        return {'success': false, 'error': 'No refresh token available'};
      }

      print('🔄 Refreshing token...');
      final response = await http
          .post(
            Uri.parse('${authUrl}token/refresh/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh': refreshToken}),
          )
          .timeout(Duration(seconds: 10));

      print('📡 Token refresh status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access']);
        print('✅ Token refreshed successfully');
        return {'success': true, 'token': data['access']};
      } else {
        print('❌ Token refresh failed: ${response.statusCode}');
        print('❌ Response: ${response.body}');

        // Clear invalid tokens
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('access_token');
        await prefs.remove('refresh_token');

        return {'success': false, 'error': 'Token refresh failed'};
      }
    } on TimeoutException {
      print('❌ Token refresh timeout');
      return {'success': false, 'error': 'Token refresh timeout'};
    } catch (e) {
      print('❌ Token refresh error: $e');
      return {'success': false, 'error': 'Token refresh error: $e'};
    }
  }

  // PDF upload with proper authentication handling
  static Future<Map<String, dynamic>> uploadPdf(File file,
      {bool isRetry = false}) async {
    print('📁 Starting PDF upload process...');
    print('📁 File: ${file.path}');
    print('📁 Size: ${file.lengthSync()} bytes');

    try {
      // Get token with better error handling
      final token = await getToken();
      if (token == null) {
        print('❌ No authentication token found');
        return {
          'success': false,
          'error': 'Not authenticated. Please login again.',
          'shouldLogout': true
        };
      }

      print('🔐 Token found: ${token.substring(0, 20)}...');

      // Create multipart request
      var request =
          http.MultipartRequest('POST', Uri.parse('${baseUrl}documents/'));

      // FIX: Use 'Bearer' for JWT tokens (since your token starts with eyJ...)
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      print('📤 Request URL: ${baseUrl}documents/');

      // Add file
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: file.path.split('/').last,
      ));

      print('🚀 Sending request...');
      var response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('📨 Response status: ${response.statusCode}');
      print(
          '📨 Response body: ${responseBody.length > 200 ? responseBody.substring(0, 200) + "..." : responseBody}');

      // Handle 401 Unauthorized error
      if (response.statusCode == 401 || response.statusCode == 403) {
        print('❌ ${response.statusCode} Authentication issue');

        // Prevent infinite recursion - only refresh once
        if (isRetry) {
          print('❌ Already retried once, giving up');
          return {
            'success': false,
            'error': 'Authentication failed after retry. Please login again.',
            'shouldLogout': true,
            'statusCode': response.statusCode
          };
        }

        // Try to refresh token
        print('🔄 Attempting token refresh...');
        final refreshResult = await _refreshToken();

        if (refreshResult['success']) {
          print('✅ Token refreshed, retrying upload...');
          // Retry with the new token
          return await uploadPdf(file, isRetry: true);
        } else {
          print('❌ Token refresh failed');
          return {
            'success': false,
            'error': 'Authentication failed. Please login again.',
            'shouldLogout': true,
            'statusCode': response.statusCode
          };
        }
      }

      // Handle HTML error responses
      if (responseBody.trim().startsWith('<!DOCTYPE') ||
          responseBody.trim().startsWith('<html>')) {
        print('❌ Server returned HTML error page');
        return {
          'success': false,
          'error': 'Server error. Please check Django terminal for details.',
          'statusCode': response.statusCode,
          'isHtmlError': true
        };
      }

      if (response.statusCode == 201) {
        print('✅ Upload successful!');
        return {'success': true, 'data': jsonDecode(responseBody)};
      } else {
        try {
          final errorData = jsonDecode(responseBody);
          return {
            'success': false,
            'error': errorData['error'] ??
                errorData['detail'] ??
                'Upload failed with status ${response.statusCode}',
            'statusCode': response.statusCode
          };
        } catch (e) {
          return {
            'success': false,
            'error':
                'Upload failed: ${response.statusCode} - ${responseBody.length > 100 ? responseBody.substring(0, 100) + "..." : responseBody}',
            'statusCode': response.statusCode
          };
        }
      }
    } on SocketException catch (e) {
      print('❌ Network error: $e');
      return {
        'success': false,
        'error': 'Network error: Cannot connect to server'
      };
    } on TimeoutException catch (e) {
      print('❌ Timeout error: $e');
      return {
        'success': false,
        'error': 'Upload timeout: Server took too long to respond'
      };
    } catch (e) {
      print('❌ Unexpected error: $e');
      return {'success': false, 'error': 'Upload failed: $e'};
    }
  }

  // Ask question
  static Future<Map<String, dynamic>> askQuestion(String question) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Not authenticated. Please login again.'
        };
      }

      final response = await http
          .post(
            Uri.parse('${baseUrl}ask/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'question': question}),
          )
          .timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Authentication failed. Please login again.'
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to get answer'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error asking question: $e'};
    }
  }

  // Get documents
  static Future<Map<String, dynamic>> getDocuments() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Not authenticated. Please login again.'
        };
      }

      final response = await http.get(
        Uri.parse('${baseUrl}documents/list/'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch documents: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error fetching documents: $e'};
    }
  }

  // Get query history
  static Future<Map<String, dynamic>> getQueryHistory() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Not authenticated. Please login again.'
        };
      }
      final response = await http.get(
        Uri.parse('${baseUrl}history/'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch history: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error fetching history: $e'};
    }
  }

  // Delete document
  static Future<Map<String, dynamic>> deleteDocument(int documentId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Not authenticated. Please login again.'
        };
      }

      final response = await http.delete(
        Uri.parse('${baseUrl}documents/$documentId/delete/'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 204) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'error': 'Failed to delete document: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error deleting document: $e'};
    }
  }

  // Logout
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      print('✅ Logged out successfully');
    } catch (e) {
      print('❌ Logout error: $e');
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
