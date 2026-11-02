import 'dart:async';

import 'package:test/test.dart';
import 'package:volley_api/volley_api.dart';

final class _M with DistinctMessage {
  final String v;
  _M(this.v);
}

final class _LoopbackChannel implements Channel<_M, _M> {
  final controller = StreamController<_M>.broadcast();
  final sent = <_M>[];

  @override
  Stream<_M> get messages => controller.stream;

  @override
  void send(_M message) => sent.add(message);
}

void main() {
  group('IngressChannel', () {
    test(
      'asIngress exposes the messages stream of the source channel',
      () async {
        final channel = _LoopbackChannel();
        final ingress = channel.asIngress();
        final got = <String>[];
        ingress.messages.listen((m) => got.add(m.v));
        channel.controller.add(_M('a'));
        await Future.delayed(Duration.zero);
        expect(got, ['a']);
      },
    );

    test('asIngress hides the send side', () {
      final ingress = _LoopbackChannel().asIngress();
      expect(ingress, isNot(isA<EgressChannel>()));
    });

    test('const factory wraps a channel', () async {
      final channel = _LoopbackChannel();
      final ingress = IngressChannel<_M>(channel);
      final got = <String>[];
      ingress.messages.listen((m) => got.add(m.v));
      channel.controller.add(_M('z'));
      await Future.delayed(Duration.zero);
      expect(got, ['z']);
    });
  });
}
