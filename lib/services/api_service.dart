import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

String get _baseUrl => dotenv.env['BASE_URL'] ?? 'http://192.168.100.53:8000';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  late Dio _dio;

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register(String name, String phone) async {
    final res = await _dio.post('/api/auth/register',
        data: {'name': name, 'phone': phone});
    return res.data;
  }

  Future<Map<String, dynamic>> login(String phone) async {
    final res = await _dio.post('/api/auth/login', data: {'phone': phone});
    return res.data;
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('/api/auth/me');
    return res.data;
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? avatarColor,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (avatarColor != null) data['avatar_color'] = avatarColor;
    final res = await _dio.patch('/api/auth/profile', data: data);
    return res.data;
  }

  // ── Categories ────────────────────────────────────────────────────────────

  Future<List<dynamic>> getCategories() async {
    final res = await _dio.get('/api/categories');
    return res.data['categories'];
  }

  // ── Leaderboard ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getGlobalLeaderboard() async {
    final res = await _dio.get('/api/leaderboard/global');
    return res.data;
  }

  Future<Map<String, dynamic>> getWeeklyLeaderboard() async {
    final res = await _dio.get('/api/leaderboard/weekly');
    return res.data;
  }

  Future<Map<String, dynamic>> getCategoryLeaderboard(String category) async {
    final res = await _dio.get('/api/leaderboard/category/$category');
    return res.data;
  }

  // ── Challenge ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createChallenge(String category) async {
    final res = await _dio.post('/api/challenge/create',
        data: {'category': category});
    return res.data;
  }

  Future<Map<String, dynamic>> getChallenge(String token) async {
    final res = await _dio.get('/api/challenge/$token');
    return res.data;
  }

  Future<Map<String, dynamic>> joinChallenge(String token) async {
    final res = await _dio.post('/api/challenge/$token/join');
    return res.data;
  }

  // ── Match ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createBotMatch(String category) async {
    final res = await _dio.post('/api/match/bot',
        queryParameters: {'category': category});
    return res.data;
  }

  // ── Daily ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDailyChallenge() async {
    final res = await _dio.get('/api/daily');
    return res.data;
  }

  Future<Map<String, dynamic>> submitDailyChallenge(
      String date, Map<String, String> answers) async {
    final res = await _dio.post('/api/daily/submit',
        data: {'challenge_date': date, 'answers': answers});
    return res.data;
  }
}
