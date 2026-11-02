import 'dart:async';

import 'package:test/test.dart';
import 'package:volley_api/volley_api.dart';

void main() {
  group('Disposable', () {
    test('can be created with a disposer function', () async {
      var disposed = false;
      final disposable = Disposable(() => disposed = true);
      await disposable.dispose();
      expect(disposed, isTrue);
    });
  });

  group('Actor', () {
    test('can be implemented and disposed', () async {
      final actor = _EchoActor();
      final received = <StringMessage>[];
      // _EchoChannel wraps a single-subscription StreamController, so an
      // added event with no listener sits in its buffer forever - and
      // close() then never completes, since a single-subscription stream
      // only delivers (and reports "done") once something is listening.
      actor.channel.messages.listen(received.add);
      actor.channel.send(StringMessage('hello'));
      await Future.delayed(Duration.zero);
      expect(received, hasLength(1));
      await actor.dispose();
    });
  });

  group('MessageBus', () {
    test('can publish and receive messages', () async {
      final bus = BaseMessageBus();
      final received = <String>[];
      bus.messages<String>().listen(received.add);
      bus.publish('hello');
      bus.publish('world');
      // BaseMessageBus's controller is a broadcast StreamController, which
      // delivers each add() asynchronously - a single microtask isn't
      // guaranteed to flush both, but everything scheduled via microtasks
      // is guaranteed to run before the event loop reaches a Timer, so
      // Duration.zero reliably waits out however many hops delivery needs.
      await Future.delayed(Duration.zero);
      expect(received, equals(['hello', 'world']));
      await bus.dispose();
    });
  });
}

class _EchoActor implements Actor<StringMessage, StringMessage> {
  final _controller = StreamController<StringMessage>();

  @override
  Channel<StringMessage, StringMessage> get channel =>
      _EchoChannel(_controller);

  @override
  Future<void> dispose() async => _controller.close();
}

class _EchoChannel implements Channel<StringMessage, StringMessage> {
  final StreamController<StringMessage> _controller;

  _EchoChannel(this._controller);

  @override
  Stream<StringMessage> get messages => _controller.stream;

  @override
  void send(StringMessage message) => _controller.add(message);

  Future<void> dispose() async => _controller.close();
}

final class StringMessage with DistinctMessage {
  final String content;

  StringMessage(this.content);
}
