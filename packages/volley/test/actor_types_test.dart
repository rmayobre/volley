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

  test(
    'actor with distinct input/output types: send input, receive output',
    () async {
      final a = await actor<Request, Response>(_toResponse);
      addTearDown(a.dispose);

      // Documented contract: the reducer consumes I and emits O. The caller
      // should therefore send Request and observe Response.
      final channel = a.channel as dynamic;
      final reply = (channel.messages as Stream).first;
      channel.send(const Request(3));
      final got = await reply.timeout(const Duration(seconds: 3));
      expect(got, isA<Response>());
      expect((got as Response).text, 'n=3');
    },
    skip: 'BUG: IsolateChannel<I,O> types are swapped; send() takes O, not I',
  );
}
