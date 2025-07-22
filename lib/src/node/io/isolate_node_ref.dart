import 'dart:async';
import 'dart:isolate';

import '../node_ref.dart';

final class IsolateNodeRef implements NodeRef {

  @override
  final String id;
  final Isolate isolate;
  final SendPort sendPort;
  final ReceivePort receivePort;
  
  final _completer = Completer();

  @override
  bool get isDisposed => _completer.isCompleted;

  @override
  Future get done => _completer.future;

  IsolateNodeRef._({
    required this.id,
    required this.isolate,
    required this.sendPort,
    required this.receivePort
  });

  factory IsolateNodeRef({
    required String id,
    required Isolate isolate,
    required SendPort sendPort,
    required ReceivePort receivePort,
  }) {
    return IsolateNodeRef._(
        id: id,
        isolate: isolate,
        sendPort: sendPort,
        receivePort: receivePort
    );
  }

  @override
  void send(Object message) {
    if (!_completer.isCompleted) sendPort.send(message);
  }

  @override
  FutureOr<void> dispose() async {
    if (isDisposed) return;
    _completer.complete();
    receivePort.close();
    isolate.kill(priority: Isolate.immediate); // should this be immediate?
  }
}