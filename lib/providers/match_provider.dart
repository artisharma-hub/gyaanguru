import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_state.dart';
import '../models/question_model.dart';
import '../services/socket_service.dart';
import 'auth_provider.dart';

final matchProvider = StateNotifierProvider<MatchNotifier, MatchState>(
  (ref) => MatchNotifier(ref),
);

class MatchNotifier extends StateNotifier<MatchState> {
  final Ref _ref;
  MatchNotifier(this._ref) : super(MatchState.initial);

  void startMatchmaking(String userId, String category, String token) {
    state = MatchState.initial.copyWith(
      phase: MatchPhase.searching,
      myId: userId,
    );
    socketService.onMessage = _handleMessage;
    socketService.connectMatchmaking(userId, category, token);
  }

  void cancelMatchmaking() {
    socketService.cancelMatchmaking();
    socketService.disconnect();
    state = MatchState.initial;
  }

  void setOpponent({
    required String opponentId,
    required String opponentName,
    required String opponentAvatarColor,
  }) {
    state = state.copyWith(
      opponentId: opponentId,
      opponentName: opponentName,
      opponentAvatarColor: opponentAvatarColor,
    );
  }

  void connectBattle(String matchId, String token) {
    final user = _ref.read(authProvider).value;
    if (user != null) {
      state = state.copyWith(myId: user.id);
    }
    socketService.onMessage = _handleMessage;
    socketService.connectBattle(matchId, token);
  }

  void submitAnswer(String questionId, String option, double timeTaken) {
    state = state.copyWith(selectedOption: option);
    socketService.sendAnswer(questionId, option, timeTaken);
  }

  void _handleMessage(Map<String, dynamic> msg) {
    final event = msg['event'] as String?;
    switch (event) {
      case 'searching':
        state = state.copyWith(phase: MatchPhase.searching);
        break;

      case 'matched':
        final opponent = msg['opponent'] as Map<String, dynamic>?;
        state = state.copyWith(
          phase: MatchPhase.matched,
          matchId: msg['match_id']?.toString(),
          player1Id: msg['player1_id']?.toString(),
          opponentId: opponent?['id']?.toString(),
          opponentName: opponent?['name']?.toString(),
          opponentAvatarColor: opponent?['avatar_color']?.toString(),
        );
        break;

      case 'battle_info':
        state = state.copyWith(
          player1Id: msg['player1_id']?.toString(),
        );
        break;

      case 'countdown':
        state = state.copyWith(
          phase: MatchPhase.countdown,
          countdown: (msg['seconds'] as num?)?.toInt() ?? 3,
        );
        break;

      case 'question':
        final qData = msg['question'] as Map<String, dynamic>?;
        if (qData == null) break;
        final q = QuestionModel.fromJson(qData);
        final updated = List<QuestionModel>.from(state.questions);
        if (!updated.any((x) => x.id == q.id)) updated.add(q);
        state = state.copyWith(
          phase: MatchPhase.playing,
          questions: updated,
          currentQuestionIndex: ((msg['index'] as num?)?.toInt() ?? 1) - 1,
          clearSelectedOption: true,
          clearCorrectOption: true,
        );
        break;

      case 'result':
        final p1Score = (msg['p1_score'] as num?)?.toInt() ?? 0;
        final p2Score = (msg['p2_score'] as num?)?.toInt() ?? 0;
        final isPlayer1 = state.player1Id != null && state.player1Id == state.myId;
        state = state.copyWith(
          phase: MatchPhase.showResult,
          correctOption: msg['correct_option']?.toString(),
          myScore: isPlayer1 ? p1Score : p2Score,
          opponentScore: isPlayer1 ? p2Score : p1Score,
        );
        break;

      case 'game_over':
        final p1Score = (msg['p1_score'] as num?)?.toInt() ?? 0;
        final p2Score = (msg['p2_score'] as num?)?.toInt() ?? 0;
        final isPlayer1 = state.player1Id != null && state.player1Id == state.myId;
        final p1Coins = (msg['p1_coins_earned'] as num?)?.toInt() ?? 0;
        final p2Coins = (msg['p2_coins_earned'] as num?)?.toInt() ?? 0;
        state = state.copyWith(
          phase: MatchPhase.finished,
          winnerId: msg['winner_id']?.toString(),
          coinsEarned: isPlayer1 ? p1Coins : p2Coins,
          myScore: isPlayer1 ? p1Score : p2Score,
          opponentScore: isPlayer1 ? p2Score : p1Score,
        );
        break;

      case 'error':
        state = state.copyWith(
          phase: MatchPhase.error,
          errorMessage:
              msg['message']?.toString() ?? 'Something went wrong',
        );
        break;

      case 'disconnected':
        if (state.phase != MatchPhase.finished) {
          state = state.copyWith(
            phase: MatchPhase.error,
            errorMessage: 'Connection lost. Please try again.',
          );
        }
        break;
    }
  }

  void reset() {
    socketService.disconnect();
    state = MatchState.initial;
  }
}
