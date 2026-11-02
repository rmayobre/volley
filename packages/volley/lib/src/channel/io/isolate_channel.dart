import 'dart:async';
import 'dart:isolate';

import 'package:volley_api/volley_api.dart';

final class IsolateChannel<I extends Message, O extends Message>
    implements Channel<I, O> {
  final ReceivePort _receivePort;
  final SendPort _sendPort;

  IsolateChannel({required ReceivePort receivePort, required SendPort sendPort})
    : _receivePort = receivePort,
      _sendPort = sendPort;

  @override
  late final Stream<I> messages =
      _receivePort.asBroadcastStream().where((msg) => msg is I).cast<I>();

  SendPort get sendPort => _sendPort;

  @override
  void send(O message) {
    try {
      _sendPort.send(message);
    } on ArgumentError catch (e) {
      throw UnsendableMessageException(message.runtimeType, e);
    }
  }
}
