import 'dart:async';

import 'package:volley_api/volley_api.dart';

import 'coroutine_message.dart';
import 'coroutine_result.dart';

final class CoroutineImpl<R> implements Coroutine<R> {
  final Channel<CoroutineResult, CoroutineMessage> _channel;
  final String _jobId;
  final _completer = Completer<R>();
  bool _isCanceled = false;
  bool _isDone = false;

  CoroutineImpl(this._channel, this._jobId);

  @override
  bool get isDone => _isDone;

  @override
  bool get isRunning => !_isDone && !_isCanceled;

  @override
  bool get isCanceled => _isCanceled;

  @override
  Future<R> get result => _completer.future;

  void complete(R value) {
    if (_isDone || _isCanceled) return;
    _isDone = true;
    _completer.complete(value);
  }

  void completeError(Object error, [StackTrace? stackTrace]) {
    if (_isDone || _isCanceled) return;
    _isDone = true;
    _completer.completeError(error, stackTrace);
  }

  @override
  void dispose() {
    if (_isDone || _isCanceled) return;
    _isCanceled = true;
    // Send a message to the executor so it kills the running sub-isolate.
    _channel.send(CoroutineDisposal(_jobId));
    _completer.completeError(const CoroutineDisposedException());
  }
}
