import 'dart:async';

import 'package:volley_api/volley_api.dart';

import '../../coroutine/coroutine_impl.dart';
import '../../coroutine/coroutine_message.dart';
import '../../coroutine/coroutine_result.dart';
import '../../singleton/web/singleton_instance.dart';

final class Bootstrapper {
  static late Channel<CoroutineResult, CoroutineMessage> coroutineChannel;

  static Future<void>? _initialization;

  /// Safe to call any number of times: the channel is only created once.
  static Future<void> initialize() => _initialization ??= _initialize();

  static Future<void> _initialize() async {
    coroutineChannel = _WebCoroutineChannel();
  }

  /// Disposes unfinished coroutines and resets so [initialize] can run again.
  /// (There is no background host on the web, so nothing else needs stopping.)
  static Future<void> shutdown() async {
    if (_initialization == null) return;
    CoroutineImpl.disposeAll();
    await disposeSingletons();
    _initialization = null;
  }
}

/// Shallow web implementation of the coroutine executor channel.
///
/// There are no isolates on the web, so [CoroutineTask.compute] just runs
/// on the caller's own thread instead of a dedicated sub-isolate.
final class _WebCoroutineChannel
    implements Channel<CoroutineResult, CoroutineMessage> {
  final _controller = StreamController<CoroutineResult>.broadcast();

  @override
  Stream<CoroutineResult> get messages => _controller.stream;

  @override
  void send(CoroutineMessage message) {
    scheduleMicrotask(() async {
      switch (message) {
        case CoroutineDisposal():
          _controller.add(CoroutineResult.cancelled(message.id));
        case CoroutineTask():
          try {
            _controller.add(
              CoroutineResult(message.id, await message.compute()),
            );
          } catch (e, st) {
            _controller.add(CoroutineResult.failed(message.id, e, '$st'));
          }
      }
    });
  }
}
