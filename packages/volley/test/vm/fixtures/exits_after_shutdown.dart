// Run as a subprocess by shutdown_test.dart: uses every part of volley, then
// shuts down, and must exit by itself.
import 'package:volley/volley.dart';

final class Ping implements Message {
  const Ping();
}

Ping _echo(Ping m) => m;

final class Counter extends SerializedSingleton<Ping, Ping> {
  @override
  Ping reduce(Ping event) => event;
}

void main() async {
  await Bootstrapper.initialize();
  print(await coroutine(() => 'coroutine ok').result);

  final channel = await Singleton.instance<Ping, Ping, Counter>(Counter.new);
  final reply = channel.messages.first;
  channel.send(const Ping());
  await reply;
  print('singleton ok');

  final a = await actor<Ping, Ping>(_echo);
  final actorReply = a.channel.messages.first;
  a.channel.send(const Ping());
  await actorReply;
  a.dispose();
  print('actor ok');

  await Bootstrapper.shutdown();
  print('shut down');
}
