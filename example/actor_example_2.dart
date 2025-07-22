import 'dart:async';
import 'dart:io';

import 'package:volley/volley.dart';

void main() async {
  Volley.init(); // Initialize framework.
  print('Spawning actor...');
  final mailbox = await spawn<int, String>((message) {
    print('Reducing message: $message');
    return '$message';
  });

  print('Finished spawning actor');

  mailbox
    ..listen(handleResponse, onError: handleError)
    ..send(0)
    ..send(1)
    ..send(2)
    ..send(3)
    ..send(4)
    ..send(5);

  print('Running delay of 3 seconds...');
  Future.delayed(Duration(seconds: 3))
    .then((_) {
      print('Exiting App...');
      exit(0);
    });
}

void handleResponse(String message) {
  print('Received a message from mailbox: $message');
}

void handleError(Object error, StackTrace? stackTrace) {
  print('Actor experienced an error: $error');
  print('Shutting down application...');
  exit(1);
}
