import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final leaderboardProvider = StateNotifierProvider<LeaderboardNotifier,
    AsyncValue<Map<String, dynamic>?>>(
  (ref) => LeaderboardNotifier(),
);

class LeaderboardNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  LeaderboardNotifier() : super(const AsyncValue.data(null));

  final _api = ApiService();

  Future<void> fetchGlobal() async {
    state = const AsyncValue.loading();
    try {
      final data = await _api.getGlobalLeaderboard();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> fetchWeekly() async {
    state = const AsyncValue.loading();
    try {
      final data = await _api.getWeeklyLeaderboard();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> fetchCategory(String category) async {
    state = const AsyncValue.loading();
    try {
      final data = await _api.getCategoryLeaderboard(category);
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
