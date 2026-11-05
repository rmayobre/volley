import 'package:test/test.dart';
import 'package:volley/volley.dart';

void main() {
  setUpAll(() => Bootstrapper.initialize());

  group('Bootstrapper', () {
    test('initialize can be called repeatedly', () async {
      await Bootstrapper.initialize();
      await Bootstrapper.initialize();
      expect(await coroutine(() => 1).result, 1);
    });
  });

  group('Bootstrapper concurrency', () {
    test('concurrent initialize calls share one initialization', () async {
      await Future.wait([
        for (var i = 0; i < 5; i++) Bootstrapper.initialize(),
      ]);
      expect(await coroutine(() => 2).result, 2);
    });
  });
}
