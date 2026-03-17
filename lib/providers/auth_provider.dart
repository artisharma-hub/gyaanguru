import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

String _friendlyError(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map) return first['msg']?.toString() ?? e.message ?? e.toString();
      }
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown) {
      return 'Cannot connect to server. Check your network.';
    }
    if (e.response?.statusCode == 404) return 'Account not found.';
    if (e.response?.statusCode == 422) return 'Invalid input. Please check your details.';
  }
  return e.toString();
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>(
  (ref) => AuthNotifier(),
);

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _loadUser();
  }

  final _api = ApiService();

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        state = const AsyncValue.data(null);
        return;
      }
      final data = await _api.getMe();
      final imagePath = prefs.getString('avatar_image_path');
      state = AsyncValue.data(
        UserModel.fromJson(data).copyWith(avatarImagePath: imagePath),
      );
    } catch (_) {
      state = const AsyncValue.data(null);
    }
  }

  /// Returns the existing name if the phone was already registered under a
  /// different name, otherwise null.
  Future<String?> register(String name, String phone) async {
    state = const AsyncValue.loading();
    try {
      final data = await _api.register(name, phone);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']?.toString() ?? '');
      state = AsyncValue.data(
          UserModel.fromJson(data['user'] as Map<String, dynamic>));
      return data['existing_name'] as String?;
    } catch (e, st) {
      state = AsyncValue.error(_friendlyError(e), st);
      return null;
    }
  }

  Future<void> updateProfile({
    String? name,
    String? avatarColor,
    String? imagePath,
  }) async {
    try {
      final data = await _api.updateProfile(name: name, avatarColor: avatarColor);
      final prefs = await SharedPreferences.getInstance();

      if (imagePath != null) {
        await prefs.setString('avatar_image_path', imagePath);
      }

      final savedImagePath =
          imagePath ?? prefs.getString('avatar_image_path');

      state = AsyncValue.data(
        UserModel.fromJson(data).copyWith(avatarImagePath: savedImagePath),
      );
    } catch (e, st) {
      state = AsyncValue.error(_friendlyError(e), st);
    }
  }

  Future<void> refreshUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = await _api.getMe();
      final imagePath = prefs.getString('avatar_image_path');
      state = AsyncValue.data(
        UserModel.fromJson(data).copyWith(avatarImagePath: imagePath),
      );
    } catch (_) {}
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('avatar_image_path');
    state = const AsyncValue.data(null);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
