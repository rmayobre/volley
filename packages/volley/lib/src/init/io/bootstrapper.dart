import 'dart:async';
import 'dart:isolate';

import 'package:volley_api/volley_api.dart';

import '../../channel/io/isolate_channel.dart';
import '../../coroutine/coroutine_executor.dart';
import '../../coroutine/coroutine_impl.dart';
import '../../coroutine/coroutine_message.dart' show CoroutineMessage;
import '../../coroutine/coroutine_result.dart';
import '../../singleton/io/singleton_actor.dart';
import '../../singleton/io/singleton_instance.dart';
import '../../singleton/io/singleton_operation.dart';
import '../../singleton/io/singleton_results.dart';
import '../../singleton/io/singleton_send_port.dart';

/// Starts and stops the infrastructure that actors, singletons and
/// coroutines share: the singleton host isolate and the coroutine executor.
///
/// It is initialized automatically on first use, so calling [initialize] is
/// optional. Call [shutdown] before the program ends, otherwise the host
/// isolate keeps the process alive.
final class Bootstrapper {
  /// The channel used by `coroutine()` to reach the coroutine executor.
  static late Channel<CoroutineResult, CoroutineMessage> coroutineChannel;

  // A caller that's spawning a new isolate and wants it to share the
  // existing singleton actor (rather than spawn its own) should set
  // singletonSendPort directly before calling this — see
  // actor/io/isolate_actor_entrypoint.dart and
  // coroutine/coroutine_executor.dart for the two places that do.
  static Future<void>? _initialization;

  /// The shared singleton host, if this isolate is the one that spawned it.
  static Actor<SingletonResult, SingletonOperation>? _host;

  /// Initializes this isolate. Safe to call any number of times, including
  /// concurrently: every call shares the same initialization.
  static Future<void> initialize() {
    final pending = _initialization ??= _initialize();
    // Allow a retry if initialization failed rather than caching the failure.
    pending.catchError((Object _) => _initialization = null).ignore();
    return pending;
  }

  static Future<void> _initialize() async {
    if (singletonSendPort == null) {
      final host = await spawnSingletonActor();
      _host = host;
      singletonSendPort = (host.channel as IsolateChannel).sendPort;
    }
    // Not Singleton.instance: that waits for this very initialization.
    coroutineChannel = await singletonInstance<
      CoroutineResult,
      CoroutineMessage,
      CoroutineExecutor
    >(CoroutineExecutor.new);
  }

  /// Stops everything [initialize] started so the program can exit.
  ///
  /// Without this, the shared singleton host keeps the process alive after
  /// `main` returns. Shutting down:
  ///
  /// * disposes every coroutine that hasn't finished (their `result` fails
  ///   with a `CoroutineDisposedException`) and kills their isolates,
  /// * calls `dispose()` on every singleton that is [Disposable],
  /// * stops the singleton host and closes the singleton channels.
  ///
  /// Actors are not touched: dispose them yourself.
  ///
  /// Afterwards [initialize] may be called again; singletons then start from
  /// scratch in a new host. Only the isolate that called [initialize] first
  /// (normally the main isolate) owns the host and may shut it down.
  static Future<void> shutdown() async {
    final pending = _initialization;
    if (pending == null) return;
    final host = _host;
    if (host == null) {
      throw StateError(
        'Bootstrapper.shutdown() can only be called from the isolate that '
        'initialized the singleton host (normally the main isolate).',
      );
    }
    try {
      await pending;
    } catch (_) {
      // A failed initialization is still shut down below.
    }

    // The disposals travel to the host before the shutdown request does (same
    // port, in order), so the executor has already handled them.
    CoroutineImpl.disposeAll();

    final replyPort = ReceivePort();
    singletonSendPort?.send(SingletonShutdown(replyTo: replyPort.sendPort));
    await replyPort.first.timeout(
      const Duration(seconds: 5),
      onTimeout: () => null,
    );
    replyPort.close();

    closeSingletonChannels();
    host.dispose();
    _host = null;
    singletonSendPort = null;
    _initialization = null;
  }
}
