import 'dart:async';
import 'dart:io';

import 'package:volley/volley.dart';

int counter = 0;

void main() async {
  Volley.init();
  final actor1 = await spawn<int, String>((message) {
    counter = counter + message;
    return 'Actor 1 Counter: $counter';
  });
  final actor2 = await spawn<int, String>((message) {
    counter = counter + message;
    return 'Actor 2 Counter: $counter';
  });

  actor1.listen((message) => print(message));
  actor2.listen((message) => print(message));

  actor1.send(1);
  actor2.send(2);
  actor1.send(3);
  actor2.send(4);
  actor1.send(5);
  actor2.send(6);
  actor1.send(7);
  actor2.send(8);

  await Future.delayed(Duration(seconds: 2));

  counter = counter + 1;
  print('Counter Zone 1: $counter');
  runZoned(() => print('Counter Zone 2: $counter'));

  exit(0);
}