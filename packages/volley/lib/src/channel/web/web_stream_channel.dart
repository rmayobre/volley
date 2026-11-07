import 'dart:async';

import 'package:meta/meta.dart';
import 'package:volley_api/volley_api.dart';

/// An in-process [Channel] for the web.
///
/// Messages passed to [send] are handed to [onSend]; whatever the owner passes
/// to [emit] is delivered on [messages].
@internal
final class WebStreamChannel<I extends Message, O extends Message>
    implements Channel<I, O>, Disposable {
  final void Function(O message) _onSend;
  final _inbound = StreamController<I>.broadcast();
  bool _closed = false;

  /// Creates a channel that passes everything sent on it to [onSend].
  WebStreamChannel({required void Function(O message) onSend})
    : _onSend = onSend;

  @override
  Stream<I> get messages => _inbound.stream;

  /// Delivers [message] to listeners of [messages]. Ignored once closed.
  void emit(I message) {
    if (!_closed) _inbound.add(message);
  }

  /// Sending to a closed channel drops the message, like sending to a dead
  /// isolate.
  @override
  void send(O message) {
    if (!_closed) _onSend(message);
  }

  @override
  Future<void> dispose() async {
    if (_closed) return;
    _closed = true;
    await _inbound.close();
  }
}
