import 'package:volley_api/volley_api.dart';

import '../../channel/io/isolate_channel.dart';
import '../../coroutine/coroutine_executor.dart';
import '../../coroutine/coroutine_message.dart' show CoroutineMessage;
import '../../coroutine/coroutine_result.dart';
import '../../singleton/singleton.dart';
import '../../singleton/io/singleton_actor.dart';
import '../../singleton/io/singleton_send_port.dart';

final class Bootstrapper {
  static late final Channel<CoroutineResult, CoroutineMessage> coroutineChannel;

  // A caller that's spawning a new isolate and wants it to share the
  // existing singleton actor (rather than spawn its own) should set
  // singletonSendPort directly before calling this — see
  // actor/io/isolate_actor_entrypoint.dart and
  // coroutine/coroutine_executor.dart for the two places that do.
  static Future<void>? _initialization;

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
      final singletonActor = await spawnSingletonActor();
      singletonSendPort = (singletonActor.channel as IsolateChannel).sendPort;
    }
    coroutineChannel = await Singleton.instance(CoroutineExecutor.new);
  }
}
