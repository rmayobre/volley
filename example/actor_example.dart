import 'dart:io';

import 'package:volley/volley.dart';

void main() async {
  Volley.init();
  final mailbox = await spawn<String, String>((message) {
    print('Received message: $message');
    return 'Responding to $message';
  });

  mailbox
    ..listen((response) => print('Received response: $response'))
    ..send('hello')
    ..send('world');

  // Delaying the exit so we can see the messages in the terminal.
  Future.delayed(Duration(seconds: 3))
      .then((_) => exit(0));
}