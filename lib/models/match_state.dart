import 'question_model.dart';

enum MatchPhase {
  idle,
  searching,
  matched,
  countdown,
  playing,
  showResult,
  finished,
  error,
}

class MatchState {
  final MatchPhase phase;
  final String? matchId;
  final String? myId;
  final String? player1Id;
  final String? opponentId;
  final String? opponentName;
  final String? opponentAvatarColor;
  final int myScore;
  final int opponentScore;
  final List<QuestionModel> questions;
  final int currentQuestionIndex;
  final String? selectedOption;
  final String? correctOption;
  final String? winnerId;
  final int coinsEarned;
  final String? errorMessage;
  final int countdown;

  const MatchState({
    this.phase = MatchPhase.idle,
    this.matchId,
    this.myId,
    this.player1Id,
    this.opponentId,
    this.opponentName,
    this.opponentAvatarColor,
    this.myScore = 0,
    this.opponentScore = 0,
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.selectedOption,
    this.correctOption,
    this.winnerId,
    this.coinsEarned = 0,
    this.errorMessage,
    this.countdown = 3,
  });

  static const MatchState initial = MatchState();

  bool get isPlayer1 => player1Id != null && player1Id == myId;
  bool get isWinner => winnerId != null && winnerId == myId;
  bool get isTie => phase == MatchPhase.finished && winnerId == null;

  QuestionModel? get currentQuestion =>
      questions.isNotEmpty && currentQuestionIndex < questions.length
          ? questions[currentQuestionIndex]
          : null;

  MatchState copyWith({
    MatchPhase? phase,
    String? matchId,
    String? myId,
    String? player1Id,
    String? opponentId,
    String? opponentName,
    String? opponentAvatarColor,
    int? myScore,
    int? opponentScore,
    List<QuestionModel>? questions,
    int? currentQuestionIndex,
    String? selectedOption,
    String? correctOption,
    String? winnerId,
    int? coinsEarned,
    String? errorMessage,
    int? countdown,
    bool clearSelectedOption = false,
    bool clearCorrectOption = false,
    bool clearWinnerId = false,
    bool clearErrorMessage = false,
  }) =>
      MatchState(
        phase: phase ?? this.phase,
        matchId: matchId ?? this.matchId,
        myId: myId ?? this.myId,
        player1Id: player1Id ?? this.player1Id,
        opponentId: opponentId ?? this.opponentId,
        opponentName: opponentName ?? this.opponentName,
        opponentAvatarColor: opponentAvatarColor ?? this.opponentAvatarColor,
        myScore: myScore ?? this.myScore,
        opponentScore: opponentScore ?? this.opponentScore,
        questions: questions ?? this.questions,
        currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
        selectedOption:
            clearSelectedOption ? null : (selectedOption ?? this.selectedOption),
        correctOption:
            clearCorrectOption ? null : (correctOption ?? this.correctOption),
        winnerId: clearWinnerId ? null : (winnerId ?? this.winnerId),
        coinsEarned: coinsEarned ?? this.coinsEarned,
        errorMessage:
            clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
        countdown: countdown ?? this.countdown,
      );
}
