// Calls Singleton.instance before anything else: must not hang.
import 'package:volley/volley.dart';

final class Ping implements Message {
  const Ping();
}

final class Echo extends SerializedSingleton<Ping, Ping> {
  @override
  Ping reduce(Ping event) => event;
}

void main() async {
  final ch = await Singleton.instance<Ping, Ping, Echo>(Echo.new);
  final reply = ch.messages.first;
  ch.send(const Ping());
  await reply;
  print('singleton first ok');
  await Bootstrapper.shutdown();
}
