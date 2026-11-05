import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:volley_workers_gen/builder.dart';

const _source = r'''
import 'package:volley_workers/volley_workers.dart';

part 'sample.gen.dart';

@volleyMessage
final class Ping implements Message {
  final String text;
  final List<int> numbers;
  final DateTime? at;
  const Ping(this.text, {required this.numbers, this.at});
}

@volleyMessage
final class Pong implements Message {
  final String text;
  const Pong(this.text);
}

@actor
Future<Pong> echo(Ping ping) async => Pong(ping.text);

@coroutine
Future<int> sum(List<int> values, String label) async => 0;
''';

Future<void> _build(String source, void Function(String) check) async {
  final readerWriter = TestReaderWriter(rootPackage: 'volley_workers_gen');
  await readerWriter.testing.loadIsolateSources();
  await testBuilder(
    workersBuilder(BuilderOptions.empty),
    {'volley_workers_gen|lib/sample.dart': source},
    readerWriter: readerWriter,
    outputs: {
      'volley_workers_gen|lib/sample.gen.dart': decodedMatches(
        predicate<String>((output) {
          check(output);
          return true;
        }),
      ),
    },
  );
}

void main() {
  test('generates actor, coroutine and message codecs', () async {
    late String generated;
    await _build(_source, (output) => generated = output);
    expect(generated, contains('part of'));
    expect(generated, contains('Future<Actor<Pong, Ping>> spawnEcho('));
    expect(generated, contains('void echoWorkerMain()'));
    expect(generated, contains('Coroutine<int> launchSum('));
    expect(generated, contains('void sumWorkerMain()'));
    expect(generated, contains(r'_$PingToMap'));
    expect(generated, contains(r'_$PongFromMap'));
  });

  test('supports enums, DateTime, nesting and nullable lists', () async {
    late String generated;
    await _build(r'''
import 'package:volley_workers/volley_workers.dart';
part 'sample.gen.dart';

enum Color { red, green }

@volleyMessage
final class Inner implements Message {
  final Color color;
  const Inner(this.color);
}

@volleyMessage
final class Outer implements Message {
  final Inner inner;
  final DateTime when;
  final List<int>? items;
  const Outer(this.inner, this.when, this.items);
}
''', (output) => generated = output);
    expect(generated, contains('Color.values.byName'));
    expect(generated, contains('_\$InnerToMap(value.inner)'));
    expect(generated, contains('DateTime.fromMillisecondsSinceEpoch'));
  });

  group('rejects', () {
    Future<String> errors(String body) async {
      final readerWriter = TestReaderWriter(rootPackage: 'volley_workers_gen');
      await readerWriter.testing.loadIsolateSources();
      final logs = <String>[];
      await testBuilder(
        workersBuilder(BuilderOptions.empty),
        {
          'volley_workers_gen|lib/sample.dart':
              "import 'dart:isolate';\n"
              "import 'package:volley_workers/volley_workers.dart';\n"
              "part 'sample.gen.dart';\n$body",
        },
        readerWriter: readerWriter,
        onLog: (record) => logs.add(record.message),
      );
      return logs.join('\n');
    }

    test('actors whose parameter is not a Message', () async {
      expect(
        await errors('@actor\nFuture<int> bad(int x) async => x;'),
        contains('@actor functions must take a Message'),
      );
    });

    test('coroutine parameters that cannot cross a worker boundary', () async {
      final log = await errors('@coroutine\nint bad(SendPort port) => 0;\n');
      expect(log, contains('cannot be sent to a worker'));
      expect(log, contains('SendPort'));
    });

    test('coroutine parameters of an unannotated class', () async {
      final log = await errors(
        'class Plain {}\n@coroutine\nint bad(Plain p) => 0;\n',
      );
      expect(log, contains('cannot be sent to a worker'));
    });

    test('maps with non-String keys', () async {
      expect(
        await errors('@coroutine\nint bad(Map<int, int> m) => 0;'),
        contains('only maps with String keys'),
      );
    });

    test('coroutines with named or optional parameters', () async {
      expect(
        await errors('@coroutine\nint bad({int x = 0}) => x;'),
        contains('required positional parameters'),
      );
    });

    test('message properties of unsupported types', () async {
      expect(
        await errors('''
@volleyMessage
final class Bad implements Message {
  final void Function() callback;
  const Bad(this.callback);
}
'''),
        contains('cannot be sent to a worker'),
      );
    });

    test('message constructor parameters without a matching field', () async {
      expect(
        await errors('''
@volleyMessage
final class Bad implements Message {
  final String other;
  Bad(String text) : other = text;
}
'''),
        contains('no matching field or getter named `text`'),
      );
    });
  });
}
