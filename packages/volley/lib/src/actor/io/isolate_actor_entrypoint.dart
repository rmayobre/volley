import 'dart:async';
import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:volley_api/volley_api.dart';

import '../../init/io/bootstrapper.dart';
import '../../singleton/io/singleton_send_port.dart';

@internal
@pragma('vm:entry-point')
void entrypoint(IsolateEntrypointArgs args) async {
  final inputPort = ReceivePort();

  // Start the message loop before bootstrapping so the singleton actor can
  // process its own SingletonInit<CoroutineExecutor> during self-init.
  //
  // listen() (not asyncMap) is intentional: asyncMap pauses the subscription
  // while its future is pending, which would deadlock nested coroutine calls
  // that queue a new message while an outer job is still executing.
  inputPort.listen((message) async {
    final response = await args.reduce(message);
    if (response == null) return;
    try {
      args.sendPort.send(response);
    } on ArgumentError catch (e) {
      throw UnsendableMessageException(response.runtimeType, e);
    }
  });

  // When singletonSendPort is null this is the root singleton actor; point it
  // at its own inputPort so Singleton.instance / coroutine() work inside jobs.
  singletonSendPort = args.singletonSendPort ?? inputPort.sendPort;
  await Bootstrapper.initialize();

  args.handshakeSendPort.send(inputPort.sendPort);
}

@internal
final class IsolateEntrypointArgs<I extends Object, O extends Object> {
  final FutureOr<O> Function(I) reducer;
  final SendPort sendPort;
  final SendPort handshakeSendPort;
  final SendPort? singletonSendPort;

  const IsolateEntrypointArgs({
    required this.reducer,
    required this.sendPort,
    required this.handshakeSendPort,
    this.singletonSendPort,
  });

  FutureOr<Object>? reduce(dynamic message) {
    if (message is! I) return null;
    return reducer(message);
  }
}
