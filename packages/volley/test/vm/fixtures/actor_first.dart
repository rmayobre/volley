// Creates an actor before anything else: must not hang.
import 'package:volley/volley.dart';

final class Ping implements Message {
  const Ping();
}

Ping _echo(Ping m) => m;

void main() async {
  final a = await actor<Ping, Ping>(_echo);
  final reply = a.channel.messages.first;
  a.channel.send(const Ping());
  await reply;
  print('actor first ok');
  a.dispose();
  await Bootstrapper.shutdown();
}
