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
