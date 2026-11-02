import 'dart:io';

import 'package:volley/volley.dart';

// Simulate a CPU-bound task by summing a range of integers.
int _sumRange(int start, int end) =>
    List.generate(end - start, (i) => start + i).fold(0, (a, b) => a + b);

void main() async {
  await Bootstrapper.initialize();

  const chunkSize = 500000;
  final ranges = List.generate(
    4,
    (i) => (start: i * chunkSize, end: (i + 1) * chunkSize),
  );

  // --- Sequential: await each coroutine before dispatching the next ---

  print('Sequential:');
  final seqStart = DateTime.now();

  final seqResults = <int>[];
  for (final r in ranges) {
    seqResults.add(await coroutine(() => _sumRange(r.start, r.end)).result);
  }

  final seqMs = DateTime.now().difference(seqStart).inMilliseconds;
  print('  sums:    ${seqResults.join(', ')}');
  print('  elapsed: ${seqMs}ms\n');

  // --- Concurrent: dispatch all coroutines, then await all results ---
  //
  // All four jobs are sent to the coroutine executor before blocking on any
  // one of them. This keeps the main isolate free and allows the executor to
  // pipeline work — especially beneficial once the executor uses multiple
  // workers (one per CPU core).

  print('Concurrent (Future.wait):');
  final conStart = DateTime.now();

  final conResults = await Future.wait([
    for (final r in ranges) coroutine(() => _sumRange(r.start, r.end)).result,
  ]);

  final conMs = DateTime.now().difference(conStart).inMilliseconds;
  print('  sums:    ${conResults.join(', ')}');
  print('  elapsed: ${conMs}ms');

  assert(seqResults.join() == conResults.join(), 'Results must match');

  exit(0);
}
