import 'dart:async';

import 'package:test/test.dart';
import 'package:volley_api/volley_api.dart';

Future<void> pump() => Future.delayed(Duration.zero);

void main() {
  group('BaseMessageBus', () {
    late BaseMessageBus bus;
    setUp(() => bus = BaseMessageBus());
    tearDown(() => bus.dispose());

    test('filters messages by type', () async {
      final strings = <String>[];
      final ints = <int>[];
      bus.messages<String>().listen(strings.add);
      bus.messages<int>().listen(ints.add);

      bus.publish('a');
      bus.publish(1);
      bus.publish('b');
      bus.publish(2);
      await pump();

      expect(strings, ['a', 'b']);
      expect(ints, [1, 2]);
    });

    test('messages<Object> receives everything', () async {
      final all = <Object>[];
      bus.messages<Object>().listen(all.add);
      bus.publish('a');
      bus.publish(1);
      await pump();
      expect(all, ['a', 1]);
    });

    test('delivers to multiple subscribers', () async {
      final a = <String>[], b = <String>[];
      bus.messages<String>().listen(a.add);
      bus.messages<String>().listen(b.add);
      bus.publish('x');
      await pump();
      expect(a, ['x']);
      expect(b, ['x']);
    });

    test('does not replay messages to late subscribers', () async {
      bus.publish('early');
      await pump();
      final received = <String>[];
      bus.messages<String>().listen(received.add);
      await pump();
      expect(received, isEmpty);
    });

    test('child bus receives parent messages, not vice versa', () async {
      final child = BaseMessageBus(parent: bus);
      addTearDown(child.dispose);
      final childGot = <String>[], parentGot = <String>[];
      child.messages<String>().listen(childGot.add);
      bus.messages<String>().listen(parentGot.add);

      bus.publish('down');
      child.publish('up');
      await pump();

      expect(childGot, containsAll(['down', 'up']));
      expect(parentGot, ['down']);
    });

    test('disposed child stops receiving parent messages', () async {
      final child = BaseMessageBus(parent: bus);
      final got = <String>[];
      child.messages<String>().listen(got.add);
      await child.dispose();
      bus.publish('late');
      await pump();
      expect(got, isEmpty);
    });

    test('dispose completes the message stream', () async {
      final local = BaseMessageBus();
      final done = Completer<void>();
      local.messages<String>().listen(null, onDone: done.complete);
      await local.dispose();
      await done.future.timeout(const Duration(seconds: 1));
    });
  });

  group('MessageBusSubscribe', () {
    test('subscribe invokes the handler for matching messages only', () async {
      final bus = BaseMessageBus();
      addTearDown(bus.dispose);
      final got = <int>[];
      bus.subscribe<int>(got.add);
      bus.publish(1);
      bus.publish('no');
      bus.publish(2);
      await pump();
      expect(got, [1, 2]);
    });

    test('proxyInto forwards messages to a sink', () async {
      final bus = BaseMessageBus();
      addTearDown(bus.dispose);
      final target = StreamController<String>();
      final got = <String>[];
      target.stream.listen(got.add);
      bus.proxyInto<String>(target.sink);
      bus.publish('hi');
      await pump();
      expect(got, ['hi']);
      await target.close();
    });

    test('canceling the subscription stops delivery', () async {
      final bus = BaseMessageBus();
      addTearDown(bus.dispose);
      final got = <int>[];
      final sub = bus.subscribe<int>(got.add);
      bus.publish(1);
      await pump();
      await sub.cancel();
      bus.publish(2);
      await pump();
      expect(got, [1]);
    });
  });
}
