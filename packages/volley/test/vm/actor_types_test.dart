@TestOn('vm')
library;

import 'package:test/test.dart';
import 'package:volley/volley.dart';

final class Request implements Message {
  final int n;
  const Request(this.n);
}

final class Response implements Message {
  final String text;
  const Response(this.text);
}

Response _toResponse(Request r) => Response('n=${r.n}');

void main() {
  setUpAll(() => Bootstrapper.initialize());

  group('actor with distinct input and output types', () {
    test(
      'the caller sends the input type and receives the output type',
      () async {
        final a = await actor<Response, Request>(_toResponse);
        addTearDown(a.dispose);

        // Compile-time check as much as a runtime one: send takes Request,
        // messages yields Response.
        final Stream<Response> responses = a.channel.messages;
        final reply = responses.first;
        a.channel.send(const Request(3));

        expect((await reply.timeout(const Duration(seconds: 3))).text, 'n=3');
      },
    );

    test('handles several round trips', () async {
      final a = await actor<Response, Request>(_toResponse);
      addTearDown(a.dispose);

      final replies = a.channel.messages.take(3).map((r) => r.text).toList();
      for (var i = 0; i < 3; i++) {
        a.channel.send(Request(i));
      }
      expect(await replies.timeout(const Duration(seconds: 3)), [
        'n=0',
        'n=1',
        'n=2',
      ]);
    });

    test('rejects unsendable input with UnsendableMessageException', () async {
      final a = await actor<Response, _Boxed>((_) => const Response('x'));
      addTearDown(a.dispose);
      var n = 0;
      expect(
        () => a.channel.send(_Boxed(() => n++)),
        throwsA(isA<UnsendableMessageException>()),
      );
    });
  });
}

final class _Boxed implements Message {
  final Object payload;
  const _Boxed(this.payload);
}
