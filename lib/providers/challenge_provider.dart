import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final challengeProvider = StateNotifierProvider<ChallengeNotifier,
    AsyncValue<Map<String, dynamic>?>>(
  (ref) => ChallengeNotifier(),
);

class ChallengeNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  ChallengeNotifier() : super(const AsyncValue.data(null));

  final _api = ApiService();

  Future<void> createChallenge(String category) async {
    state = const AsyncValue.loading();
    try {
      final data = await _api.createChallenge(category);
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Map<String, dynamic>?> getChallenge(String token) async {
    try {
      return await _api.getChallenge(token);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> joinChallenge(String token) async {
    try {
      return await _api.joinChallenge(token);
    } catch (_) {
      return null;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}
