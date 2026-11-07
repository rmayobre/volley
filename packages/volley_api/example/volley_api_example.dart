// A taste of the platform-agnostic utilities in volley_api. The actor,
// coroutine and singleton implementations live in package:volley.
import 'package:volley_api/volley_api.dart';

final class Greeting {
  final String text;
  const Greeting(this.text);
}

Future<void> main() async {
  // MessageBus: publish a value, subscribers of its type receive it.
  final bus = BaseMessageBus();
  final received = bus.messages<Greeting>().first;
  bus.publish(const Greeting('hello'));
  print((await received).text);

  // Pool: a fixed number of lazily created resources, shared by callers.
  final pool = Pool<int>(2, (index) => index);
  final doubled = await Future.wait([
    for (var i = 0; i < 4; i++)
      Future.value(pool.execute<int>((resource) => resource * 2)),
  ]);
  print(doubled);

  await pool.dispose();
  await bus.dispose();
}
