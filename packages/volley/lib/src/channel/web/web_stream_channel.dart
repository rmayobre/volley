import 'dart:async';

import 'package:meta/meta.dart';
import 'package:volley_api/volley_api.dart';

@internal
final class WebStreamChannel<I extends Message, O extends Message>
    implements Channel<I, O>, Disposable {
  final _inbound = StreamController<I>.broadcast();
  final _outbound = StreamController<O>.broadcast();

  @override
  Stream<I> get messages => _inbound.stream;

  @override
  void send(O message) => _outbound.add(message);

  @override
  FutureOr<void> dispose() async {
    await _inbound.close();
    await _outbound.close();
  }
}
