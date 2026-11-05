@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:test/test.dart';
import 'package:volley/volley.dart';

final class Cmd implements Message {
  final String? markerPath;
  const Cmd([this.markerPath]);
}

final class Out implements Message {
  const Out();
}

/// Records when it is disposed by writing to a file: the singleton lives in
/// the host isolate, so a file is the only thing both sides can see.
final class Tracked extends SerializedSingleton<Out, Cmd>
    implements Disposable {
  String? _markerPath;

  @override
  Out reduce(Cmd event) {
    _markerPath = event.markerPath ?? _markerPath;
    return const Out();
  }

  @override
  void dispose() {
    final path = _markerPath;
    if (path != null) File(path).writeAsStringSync('disposed');
  }
}

Future<Directory> _packageRoot() async {
  final uri = await Isolate.resolvePackageUri(
    Uri.parse('package:volley/volley.dart'),
  );
  return Directory.fromUri(uri!.resolve('../'));
}

/// Runs a fixture in its own process; returns null if it was still running
/// after [limit] (and kills it).
Future<({int? exitCode, String output})> _run(
  String fixture,
  Duration limit,
) async {
  final root = await _packageRoot();
  final process = await Process.start(Platform.resolvedExecutable, [
    'run',
    'test/vm/fixtures/$fixture',
  ], workingDirectory: root.path);
  final output = StringBuffer();
  process.stdout.transform(utf8.decoder).listen(output.write);
  process.stderr.transform(utf8.decoder).listen(output.write);

  int? code;
  try {
    code = await process.exitCode.timeout(limit);
  } on TimeoutException {
    process.kill(ProcessSignal.sigkill);
    await process.exitCode;
  }
  return (exitCode: code, output: output.toString());
}

void main() {
  group('process exit', () {
    test('a program exits by itself after Bootstrapper.shutdown()', () async {
      final r = await _run('exits_after_shutdown.dart', Duration(seconds: 60));
      expect(r.exitCode, 0, reason: r.output);
      expect(r.output, contains('shut down'));
    });

    test('control: without shutdown() the process stays alive', () async {
      final r = await _run('no_shutdown.dart', Duration(seconds: 15));
      expect(r.output, contains('coroutine ok'));
      expect(r.exitCode, isNull, reason: 'process should still be running');
    });

    test('Singleton.instance works as the very first call', () async {
      final r = await _run('singleton_first.dart', Duration(seconds: 60));
      expect(r.exitCode, 0, reason: r.output);
      expect(r.output, contains('singleton first ok'));
    });

    test('actor() works as the very first call', () async {
      final r = await _run('actor_first.dart', Duration(seconds: 60));
      expect(r.exitCode, 0, reason: r.output);
      expect(r.output, contains('actor first ok'));
    });
  });

  group('Bootstrapper.shutdown', () {
    setUp(() => Bootstrapper.initialize());
    tearDown(() => Bootstrapper.shutdown());

    test('disposes Disposable singletons', () async {
      final dir = Directory.systemTemp.createTempSync('volley_shutdown_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final marker = '${dir.path}/marker';

      final ch = await Singleton.instance<Out, Cmd, Tracked>(Tracked.new);
      final reply = ch.messages.first;
      ch.send(Cmd(marker));
      await reply;
      expect(File(marker).existsSync(), isFalse);

      await Bootstrapper.shutdown();
      expect(File(marker).readAsStringSync(), 'disposed');
    });

    test('kills running coroutines and fails their result', () async {
      final c = coroutine(() => Completer<int>().future);
      final failure = expectLater(
        c.result,
        throwsA(isA<CoroutineDisposedException>()),
      );
      await Future.delayed(const Duration(milliseconds: 100));

      await Bootstrapper.shutdown();
      await failure;
    });
  });
}
