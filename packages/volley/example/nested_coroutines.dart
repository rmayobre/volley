import 'package:volley/volley.dart';

void main() async {
  await Bootstrapper.initialize();
  final message = "Hello, World!";
  final messageFromNestedCoroutine =
      await coroutine(() async {
        return await coroutine(
          () => 'Message from nested coroutine: $message',
        ).result;
      }).result;
  print(messageFromNestedCoroutine);
  await Bootstrapper.shutdown(); // lets the program exit on its own
}
