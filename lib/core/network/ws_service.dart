import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';
import '../config/app_config.dart';

/// Simplified WebSocket service using web_socket_channel
class WsService {
  WebSocketChannel? _channel;
  final Map<String, List<Function(Map<String, dynamic>)>> _listeners = {};
  Timer? _reconnectTimer;
  String? _token;
  bool _disposed = false;

  void connect(String token, {String namespace = '/pos'}) {
    _token = token;
    _disposed = false;
    final uri = Uri.parse('${AppConfig.wsBaseUrl}$namespace?token=$token');
    try {
      _channel = WebSocketChannel.connect(uri);
      _channel!.stream.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String) as Map<String, dynamic>;
            final event = msg['event'] as String?;
            final payload = msg['data'] as Map<String, dynamic>? ?? {};
            if (event != null && _listeners.containsKey(event)) {
              for (final cb in _listeners[event]!) {
                cb(payload);
              }
            }
          } catch (_) {}
        },
        onDone: () => _scheduleReconnect(namespace),
        onError: (_) => _scheduleReconnect(namespace),
      );
    } catch (_) {
      _scheduleReconnect(namespace);
    }
  }

  void _scheduleReconnect(String namespace) {
    if (_disposed || _token == null) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      const Duration(milliseconds: AppConfig.wsReconnectDelayMs),
      () => connect(_token!, namespace: namespace),
    );
  }

  void on(String event, Function(Map<String, dynamic>) callback) {
    _listeners.putIfAbsent(event, () => []).add(callback);
  }

  void off(String event) {
    _listeners.remove(event);
  }

  void emit(String event, Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode({'event': event, 'data': data}));
  }

  void disconnect() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _listeners.clear();
  }
}

final wsServiceProvider = Provider<WsService>((ref) {
  final ws = WsService();
  ref.onDispose(() => ws.disconnect());
  return ws;
});
