import 'package:test/test.dart';
import 'package:volley/volley.dart';

int _throws() => throw StateError('compute failed');

// Kept in its own file (= its own test process) because a failure here may
// take down the shared singleton isolate and break unrelated tests.
void main() {
  setUpAll(() => Bootstrapper.initialize());

  test(
    'a throwing computation surfaces an error instead of hanging',
    () async {
      final c = coroutine(_throws);
      await expectLater(
        c.result.timeout(const Duration(seconds: 3)),
        throwsA(isA<StateError>()),
      );
    },
    skip:
        'BUG: a throwing computation never completes `result` (error is lost in the singleton isolate)',
  );
}
