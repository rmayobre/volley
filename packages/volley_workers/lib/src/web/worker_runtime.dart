import 'dart:async';
import 'dart:js_interop';

import 'package:volley_api/volley_api.dart';
import 'package:web/web.dart' as web;

// Wire protocol (all payloads are JS-safe via jsify/dartify):
//   worker -> host  {t: 'ready'}                      actor handshake
//   host   -> worker {t: 'msg', d: <map>}             actor input
//   worker -> host  {t: 'msg', d: <map>}              actor output
//   host   -> worker {t: 'run', a: <list>}            coroutine start
//   worker -> host  {t: 'result', v: <value>}         coroutine result
//   worker -> host  {t: 'error', e: <string>}         failure (either kind)

JSAny? _pack(Map<String, Object?> envelope) => envelope.jsify();

Map<String, Object?> _unpack(JSAny? data) =>
    (data.dartify() as Map).cast<String, Object?>();

Map<String, Object?> _asMap(Object? value) =>
    (value as Map).cast<String, Object?>();

Object _toError(web.Event event) {
  final message =
      event.isA<web.ErrorEvent>()
          ? (event as web.ErrorEvent).message
          : 'unknown error';
  return StateError('Worker failed: $message');
}

final class _WebWorkerChannel<I extends Message, O extends Message>
    implements Channel<I, O> {
  final void Function(O) _onSend;
  final _inbound = StreamController<I>.broadcast();
  bool _closed = false;

  _WebWorkerChannel(this._onSend);

  @override
  Stream<I> get messages => _inbound.stream;

  void emit(I message) {
    if (!_closed) _inbound.add(message);
  }

  @override
  void send(O message) {
    if (!_closed) _onSend(message);
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _inbound.close();
  }
}

final class _WebWorkerActor<I extends Message, O extends Message>
    implements Actor<I, O> {
  final web.Worker _worker;
  final _closed = Completer<Object?>();
  @override
  late final Channel<I, O> channel;
  late final _WebWorkerChannel<I, O> _channel;

  _WebWorkerActor(
    this._worker,
    Map<String, Object?> Function(O) encodeInput,
    I Function(Map<String, Object?>) decodeOutput,
  ) {
    _channel = _WebWorkerChannel<I, O>((message) {
      try {
        _worker.postMessage(_pack({'t': 'msg', 'd': encodeInput(message)}));
      } catch (error) {
        throw UnsendableMessageException(message.runtimeType, error);
      }
    });
    channel = _channel;
    _worker.onmessage =
        ((web.MessageEvent event) {
          final envelope = _unpack(event.data);
          switch (envelope['t']) {
            case 'msg':
              _channel.emit(decodeOutput(_asMap(envelope['d'])));
            case 'error':
              _close(StateError(envelope['e'] as String));
          }
        }).toJS;
    _worker.onerror =
        ((web.Event event) {
          _close(_toError(event));
        }).toJS;
  }

  @override
  Future<Object?> get closed => _closed.future;

  Future<void> _close(Object? error) async {
    if (_closed.isCompleted) return;
    _closed.complete(error);
    _worker.terminate();
    await _channel.close();
  }

  @override
  Future<void> dispose() => _close(null);
}

/// Starts the web worker compiled at [workerScript] and returns an [Actor]
/// that talks to it. Completes once the worker reports it is ready.
Future<Actor<I, O>> spawnActorWorker<I extends Message, O extends Message>({
  required FutureOr<I> Function(O) reducer,
  required String workerScript,
  required Map<String, Object?> Function(O) encodeInput,
  required I Function(Map<String, Object?>) decodeOutput,
}) async {
  final worker = web.Worker(workerScript.toJS);
  final ready = Completer<void>();
  worker.onmessage =
      ((web.MessageEvent event) {
        if (_unpack(event.data)['t'] == 'ready' && !ready.isCompleted) {
          ready.complete();
        }
      }).toJS;
  worker.onerror =
      ((web.Event event) {
        if (!ready.isCompleted) ready.completeError(_toError(event));
      }).toJS;
  try {
    await ready.future;
  } catch (_) {
    worker.terminate();
    rethrow;
  }
  return _WebWorkerActor<I, O>(worker, encodeInput, decodeOutput);
}

final class _WebWorkerCoroutine<R> implements Coroutine<R> {
  final web.Worker _worker;
  final _result = Completer<R>();
  bool _canceled = false;

  _WebWorkerCoroutine(
    this._worker,
    List<Object?> args,
    R Function(Object?) decodeResult,
  ) {
    // Surface failures through [result] only; avoid unhandled-error noise if
    // nobody listens.
    _result.future.ignore();
    _worker.onmessage =
        ((web.MessageEvent event) {
          final envelope = _unpack(event.data);
          switch (envelope['t']) {
            case 'ready':
              try {
                _worker.postMessage(_pack({'t': 'run', 'a': args}));
              } catch (error) {
                _finish(error: UnsendableMessageException(Object, error));
              }
            case 'result':
              try {
                _finish(value: decodeResult(envelope['v']));
              } catch (error) {
                _finish(error: error);
              }
            case 'error':
              _finish(error: StateError(envelope['e'] as String));
          }
        }).toJS;
    _worker.onerror =
        ((web.Event event) {
          _finish(error: _toError(event));
        }).toJS;
  }

  void _finish({R? value, Object? error}) {
    if (_result.isCompleted) return;
    _worker.terminate();
    if (error != null) {
      _result.completeError(error);
    } else {
      _result.complete(value as R);
    }
  }

  @override
  bool get isDone => _result.isCompleted && !_canceled;

  @override
  bool get isRunning => !_result.isCompleted;

  @override
  bool get isCanceled => _canceled;

  @override
  Future<R> get result => _result.future;

  @override
  void dispose() {
    if (_result.isCompleted) return;
    _canceled = true;
    _worker.terminate();
    _result.completeError(const CoroutineDisposedException());
  }
}

/// Runs the coroutine in the web worker compiled at [workerScript].
Coroutine<R> launchCoroutineWorker<R>({
  required FutureOr<R> Function() compute,
  required String workerScript,
  required List<Object?> args,
  required R Function(Object?) decodeResult,
}) => _WebWorkerCoroutine<R>(web.Worker(workerScript.toJS), args, decodeResult);

web.DedicatedWorkerGlobalScope get _scope =>
    globalContext as web.DedicatedWorkerGlobalScope;

/// Worker side of an actor: call this from the worker's `main`.
void runActorWorker<I extends Message, O extends Message>({
  required FutureOr<I> Function(O) reducer,
  required O Function(Map<String, Object?>) decodeInput,
  required Map<String, Object?> Function(I) encodeOutput,
}) {
  var queue = Future<void>.value();
  _scope.onmessage =
      ((web.MessageEvent event) {
        final envelope = _unpack(event.data);
        if (envelope['t'] != 'msg') return;
        // One message at a time, in order, like the isolate implementation.
        queue = queue.then((_) async {
          try {
            final response = await reducer(decodeInput(_asMap(envelope['d'])));
            _scope.postMessage(
              _pack({'t': 'msg', 'd': encodeOutput(response)}),
            );
          } catch (error) {
            _scope.postMessage(_pack({'t': 'error', 'e': error.toString()}));
          }
        });
      }).toJS;
  _scope.postMessage(_pack({'t': 'ready'}));
}

/// Worker side of a coroutine: call this from the worker's `main`.
void runCoroutineWorker<R>({
  required FutureOr<R> Function(List<Object?> args) run,
  required Object? Function(R) encodeResult,
}) {
  _scope.onmessage =
      ((web.MessageEvent event) {
        final envelope = _unpack(event.data);
        if (envelope['t'] != 'run') return;
        () async {
          try {
            final value = await run((envelope['a'] as List).cast<Object?>());
            _scope.postMessage(
              _pack({'t': 'result', 'v': encodeResult(value)}),
            );
          } catch (error) {
            _scope.postMessage(_pack({'t': 'error', 'e': error.toString()}));
          }
        }();
      }).toJS;
  _scope.postMessage(_pack({'t': 'ready'}));
}
