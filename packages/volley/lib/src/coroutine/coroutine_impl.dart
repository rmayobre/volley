import 'dart:async';

import 'package:volley_api/volley_api.dart';

import 'coroutine_message.dart';
import 'coroutine_result.dart';

/// The [Coroutine] handle returned by `coroutine()`.
///
/// Completed by the listener in `coroutine()` when the executor reports a
/// result; disposing it asks the executor to cancel the job.
final class CoroutineImpl<R> implements Coroutine<R> {
  final Channel<CoroutineResult, CoroutineMessage> _channel;
  final String _jobId;
  final _completer = Completer<R>();
  bool _isCanceled = false;
  bool _isDone = false;

  /// Coroutines started in this isolate that haven't settled yet.
  static final _live = <CoroutineImpl<dynamic>>{};

  /// Disposes every unfinished coroutine (used by `Bootstrapper.shutdown()`).
  static void disposeAll() {
    for (final c in _live.toList()) {
      c.dispose();
    }
  }

  /// Tracks the job [_jobId] that was sent over [_channel].
  CoroutineImpl(this._channel, this._jobId) {
    _live.add(this);
    _completer.future.then<void>(
      (_) => _live.remove(this),
      onError: (_) => _live.remove(this),
    );
  }

  @override
  bool get isDone => _isDone;

  @override
  bool get isRunning => !_isDone && !_isCanceled;

  @override
  bool get isCanceled => _isCanceled;

  @override
  Future<R> get result => _completer.future;

  /// Completes [result] with [value]. Ignored once done or canceled.
  void complete(R value) {
    if (_isDone || _isCanceled) return;
    _isDone = true;
    _completer.complete(value);
  }

  /// Fails [result]. Ignored once done or canceled.
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
