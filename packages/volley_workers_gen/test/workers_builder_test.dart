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

  test('rejects actors whose parameter is not a Message', () async {
    const bad = '''
import 'package:volley_workers/volley_workers.dart';
part 'sample.gen.dart';

@actor
Future<int> bad(int x) async => x;
''';
    final readerWriter = TestReaderWriter(rootPackage: 'volley_workers_gen');
    await readerWriter.testing.loadIsolateSources();
    final logs = <String>[];
    await testBuilder(
      workersBuilder(BuilderOptions.empty),
      {'volley_workers_gen|lib/sample.dart': bad},
      readerWriter: readerWriter,
      onLog: (record) => logs.add(record.message),
    );
    expect(logs.join('\n'), contains('@actor functions must take a Message'));
  });
}
