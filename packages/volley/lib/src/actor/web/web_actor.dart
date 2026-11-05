import 'dart:async';

import 'package:meta/meta.dart';
import 'package:volley_api/volley_api.dart';

import '../../channel/web/web_stream_channel.dart';

/// An [Actor] that runs its reducer on the main thread.
///
/// Obtain an instance via the [actor] function.
///
/// Messages are handled one at a time, in the order they were sent. If the
/// reducer throws, the actor closes itself: [closed] completes with the error,
/// the response stream ends, and later messages are dropped.
@internal
final class WebActor<I extends Message, O extends Message>
    implements Actor<I, O> {
  @override
  late final WebStreamChannel<I, O> channel;

  final FutureOr<I> Function(O) _reducer;
  final _closed = Completer<Object?>();
  Future<void> _queue = Future.value();

  WebActor(this._reducer) {
    channel = WebStreamChannel<I, O>(onSend: _enqueue);
  }

  @override
  Future<Object?> get closed => _closed.future;

  void _enqueue(O message) {
    _queue = _queue.then((_) => _handle(message));
  }

  Future<void> _handle(O message) async {
    if (_closed.isCompleted) return;
    final I response;
    try {
      response = await _reducer(message);
    } catch (error) {
      await _close(error);
      return;
    }
    channel.emit(response);
  }

  Future<void> _close(Object? error) async {
    if (_closed.isCompleted) return;
    _closed.complete(error);
    await channel.dispose();
  }

  @override
  Future<void> dispose() => _close(null);
}
