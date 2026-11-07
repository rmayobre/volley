// Counts the words in files, in parallel, using only `package:volley`.
//
//   dart run bin/main.dart README.md ../../README.md
//
// It shows all three primitives:
//   * coroutine()  - one isolate-backed job per file
//   * actor()      - a long-lived isolate that formats each result
//   * Singleton    - a running total shared by every caller
import 'dart:io';

import 'package:volley/volley.dart';

/// A finished count for one file.
final class FileCount implements Message {
  final String path;
  final int words;
  const FileCount(this.path, this.words);
}

/// A formatted line, produced by the actor.
final class Line implements Message {
  final String text;
  const Line(this.text);
}

/// Adds [words] to the running total.
final class AddWords implements Message {
  final int words;
  const AddWords(this.words);
}

/// The running total so far.
final class Total implements Message {
  final int words;
  const Total(this.words);
}

/// One instance for the whole program, however many isolates ask for it.
final class Totals extends SerializedSingleton<Total, AddWords> {
  int _words = 0;

  @override
  Total reduce(AddWords event) => Total(_words += event.words);
}

/// Runs in a coroutine isolate. Top-level so it can cross the isolate
/// boundary.
int countWords(String path) {
  final text = File(path).readAsStringSync();
  return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
}

/// The actor's reducer: formats a result. Top-level for the same reason.
Line format(FileCount count) =>
    Line('${count.words.toString().padLeft(8)}  ${count.path}');

Future<void> main(List<String> paths) async {
  if (paths.isEmpty) {
    stderr.writeln('usage: dart run bin/main.dart <file>...');
    exitCode = 64;
    return;
  }

  // Needed before coroutine() and Singleton; actor() would call it for us.
  await Bootstrapper.initialize();

  final formatter = await actor<Line, FileCount>(format);

  // Start every job before awaiting any, so the files are counted in parallel.
  final jobs = [
    for (final path in paths)
      (path: path, job: coroutine(() => countWords(path))),
  ];

  var total = 0;
  for (final (:path, :job) in jobs) {
    try {
      final words = await job.result;

      // The actor answers messages in the order they were sent.
      final line = formatter.channel.messages.first;
      formatter.channel.send(FileCount(path, words));
      print((await line).text);

      // request() returns the reply to *this* message.
      total =
          (await Singleton.request<Total, AddWords, Totals>(
            Totals.new,
            AddWords(words),
          )).words;
    } on Object catch (error) {
      stderr.writeln('$path: $error');
    }
  }

  print('${total.toString().padLeft(8)}  total');

  await formatter.dispose();
  await Bootstrapper.shutdown(); // lets the process exit
}
