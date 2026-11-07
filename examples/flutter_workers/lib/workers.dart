// Everything that runs off the UI thread: an actor, a coroutine and a
// singleton. `workers.gen.dart` is generated:
//
//   dart run build_runner build
import 'package:volley_workers/volley_workers.dart';

part 'workers.gen.dart';

/// Asks the actor to analyze all primes below [limit].
@encodable
final class AnalyzeRequest implements Message {
  final int limit;
  const AnalyzeRequest(this.limit);
}

/// What the actor found.
@encodable
final class AnalyzeReport implements Message {
  final int limit;
  final int count;
  final int largest;
  final int milliseconds;

  /// How many analyses have run so far, across every worker and the UI.
  final int runs;

  const AnalyzeReport({
    required this.limit,
    required this.count,
    required this.largest,
    required this.milliseconds,
    required this.runs,
  });
}

/// Sent to [RunLog] every time an analysis finishes.
@encodable
final class RunStarted implements Message {
  const RunStarted();
}

/// The number of runs recorded by [RunLog].
@encodable
final class RunCount implements Message {
  final int runs;
  const RunCount(this.runs);
}

/// One instance for the whole app. On the web it lives on the UI page and
/// workers reach it by message passing; on mobile and desktop every isolate
/// shares it.
@singleton
final class RunLog extends SerializedSingleton<RunCount, RunStarted> {
  int _runs = 0;

  @override
  RunCount reduce(RunStarted event) => RunCount(++_runs);
}

/// Sieve of Eratosthenes: the primes below [limit].
List<int> primesBelow(int limit) {
  if (limit < 3) return const [];
  final composite = List<bool>.filled(limit, false);
  final primes = <int>[];
  for (var i = 2; i < limit; i++) {
    if (composite[i]) continue;
    primes.add(i);
    for (var j = i * i; j < limit; j += i) {
      composite[j] = true;
    }
  }
  return primes;
}

/// A long-lived worker: send [AnalyzeRequest]s, receive [AnalyzeReport]s.
@actor
Future<AnalyzeReport> analyze(AnalyzeRequest request) async {
  final watch = Stopwatch()..start();
  final primes = primesBelow(request.limit);
  watch.stop();
  final runs = await requestRunLog(const RunStarted());
  return AnalyzeReport(
    limit: request.limit,
    count: primes.length,
    largest: primes.isEmpty ? 0 : primes.last,
    milliseconds: watch.elapsedMilliseconds,
    runs: runs.runs,
  );
}

/// A one-shot worker: how many primes are below [limit].
@coroutine
Future<int> countPrimes(int limit) async => primesBelow(limit).length;
