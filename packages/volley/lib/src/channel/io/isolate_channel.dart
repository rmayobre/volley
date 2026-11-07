import 'dart:async';
import 'dart:isolate';

import 'package:volley_api/volley_api.dart';

/// A [Channel] over a pair of isolate ports.
///
/// Incoming messages arrive on the receive port and are filtered to type [I];
/// outgoing ones go through the other isolate's [SendPort]. Sending a value
/// that cannot cross the isolate boundary throws an
/// [UnsendableMessageException].
final class IsolateChannel<I extends Message, O extends Message>
    implements Channel<I, O> {
  final ReceivePort _receivePort;
  final SendPort _sendPort;

  /// Creates a channel receiving on [receivePort] and sending to [sendPort].
  IsolateChannel({required ReceivePort receivePort, required SendPort sendPort})
    : _receivePort = receivePort,
      _sendPort = sendPort;

  @override
  late final Stream<I> messages =
      _receivePort.asBroadcastStream().where((msg) => msg is I).cast<I>();

  /// The port that delivers messages to the other end.
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
