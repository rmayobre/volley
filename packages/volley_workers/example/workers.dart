import 'package:volley_workers/volley_workers.dart';

part 'workers.gen.dart';

@encodable
final class Ping implements Message {
  final String text;
  final List<int> numbers;
  final DateTime? at;
  const Ping(this.text, {required this.numbers, this.at});
}

@encodable
final class Pong implements Message {
  final String text;
  final int total;
  const Pong(this.text, this.total);
}

@actor
Future<Pong> echo(Ping ping) async =>
    Pong(ping.text.toUpperCase(), ping.numbers.fold<int>(0, (a, b) => a + b));

@coroutine
Future<int> sum(List<int> values, int offset) async =>
    values.fold<int>(offset, (a, b) => a + b);

@encodable
final class Add implements Message {
  final int amount;
  const Add(this.amount);
}

@encodable
final class Total implements Message {
  final int value;
  const Total(this.value);
}

/// Shared state. On the web it lives on the page and workers reach it by
/// message passing; on the VM every isolate shares one instance.
@singleton
final class Counter extends SerializedSingleton<Total, Add> {
  int _total = 0;

  @override
  Total reduce(Add event) => Total(_total += event.amount);
}

@actor
Future<Total> accumulate(Add add) => requestCounter(add);

@coroutine
Future<int> bump(int by) async => (await requestCounter(Add(by))).value;
