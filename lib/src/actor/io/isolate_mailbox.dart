import 'dart:async';
import 'dart:isolate';

import '../../node/io/isolate_node_ref.dart';
import '../../node/node.dart';
import '../../node/node_ref.dart';
import '../mailbox.dart';
import '../spawn.dart';
import 'isolate_bundle.dart';
import 'isolate_response.dart';

final class IsolateMailbox<I extends Object, O extends Object>
    extends Stream<O> implements Mailbox<I, O> {

  // Outbound Messaging
  final _outbound = StreamController<O>.broadcast();

  final IsolateNodeRef node;

  late final StreamSubscription<IsolateMessage> _subscription;

  @override
  bool get isOpen => !node.isDisposed;

  IsolateMailbox({required this.node}) {
    _subscription = node.receivePort
        .where((message) => message is IsolateMessage)
        .cast<IsolateMessage>()
        .listen(_handleMessage);
  }

  /// Spawns an [Isolate] that constructs an [Actor] to handle incoming messages and outgoing responses.
  ///
  /// [factory] will be passed to the Entrypoint of the Isolate to construct the [Actor] in the Zone of another
  /// Isolate. This achieves concurrent computations and messaging state.
  ///
  /// [name] provides a debugging name the keep track of the isolate associated.
  static Future<IsolateMailbox<I, O>> spawn<I extends Object, O extends Object>(ActorFactory<I, O> factory) async {
    final firstResponse = Completer();
    final rawPort = RawReceivePort((message) => firstResponse.complete(message));
    final nodeId = NodeRef.createId();
    final bundle = IsolateBundle(
      id: nodeId,
      create: factory,
      sendPort: rawPort.sendPort,
    );
    final node = IsolateNodeRef(
      id: nodeId,
      isolate: await Isolate.spawn(_entryPoint, bundle,
        // debugName: name,
        // onExit: ,
        // errorsAreFatal: true
      ),
      sendPort: await firstResponse.future as SendPort,
      receivePort: ReceivePort.fromRawReceivePort(rawPort),
    );
    Node.current.register(node);
    return IsolateMailbox(node: node);
  }

  @override
  StreamSubscription<O> listen(void Function(O event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError
  }) => _outbound.stream.listen(
      onData,
      onDone: onDone,
      onError: onError,
      cancelOnError: cancelOnError
  );

  @override
  void send(I message) => node.send(message);
  
  @override
  FutureOr<void> dispose() async {
    await node.dispose();
    Future.wait(<Future>[
      _subscription.cancel(),
      _outbound.close()
    ]);
  }

  void _handleMessage(IsolateMessage message) {
    switch(message) {
      case IsolateResponse():
        _outbound.add(message.value as O);
      case IsolateError():
        _outbound.addError(message.error, message.stackTrace);
        dispose();
    }
  }
}

void _entryPoint(IsolateBundle bundle) async {
  try {
    bundle.initActor();
    final receivePort = ReceivePort();
    final controller = StreamController(sync: true)..addStream(receivePort);
    final incomingMessages = controller.stream
      .map<FutureOr<dynamic>?>(bundle.reduce)
      .where((futureResponse) => futureResponse != null)
      .cast<FutureOr<dynamic>>()
      .asyncMap((futureResponse) async => await futureResponse);
    bundle.sendPort.send(receivePort.sendPort);
    await for (final message in incomingMessages) {
      final response = IsolateResponse(message);
      bundle.sendPort.send(response);
    }
  } catch (error, stackTrace) {
    final message = IsolateError(error, stackTrace);
    bundle.sendPort.send(message);
    rethrow;
  }
}