import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

const _wsBase = 'ws://192.168.100.53:8000';

class SocketService {
  WebSocketChannel? _channel;
  Function(Map<String, dynamic>)? onMessage;

  void _listen() {
    _channel!.stream.listen(
      (raw) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        onMessage?.call(data);
      },
      onError: (e) => onMessage?.call({'event': 'error', 'message': e.toString()}),
      onDone: () => onMessage?.call({'event': 'disconnected'}),
    );
  }

  // ── Matchmaking ──────────────────────────────────────────────────────────

  void connectMatchmaking(String userId, String category, String token) {
    _channel?.sink.close();
    final uri = Uri.parse(
        '$_wsBase/ws/match/$userId?category=$category&token=$token');
    _channel = WebSocketChannel.connect(uri);
    _listen();
  }

  // ── Battle ───────────────────────────────────────────────────────────────

  void connectBattle(String matchId, String token) {
    _channel?.sink.close();
    final uri = Uri.parse('$_wsBase/ws/battle/$matchId?token=$token');
    _channel = WebSocketChannel.connect(uri);
    _listen();
  }

  // ── Send / control ────────────────────────────────────────────────────────

  void send(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  void sendAnswer(String questionId, String option, double timeTaken) {
    send({
      'event': 'answer',
      'question_id': questionId,
      'option': option,
      'time_taken': timeTaken,
    });
  }

  void cancelMatchmaking() {
    send({'event': 'cancel'});
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}

final socketService = SocketService();
