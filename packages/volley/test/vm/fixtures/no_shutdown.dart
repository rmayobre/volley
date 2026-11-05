// Control for shutdown_test.dart: identical, but never shuts down, so the
// process is expected to stay alive.
import 'package:volley/volley.dart';

void main() async {
  await Bootstrapper.initialize();
  print(await coroutine(() => 'coroutine ok').result);
}
