import 'dart:io';
import 'dart:isolate';

import 'package:volley/volley.dart';

void main() async {
  final coroutineOne = launch(() => print("From Coroutine 1 - we're in Isolate ${Isolate.current.debugName}"));
  final coroutineTwo = launch(() => print("From Coroutine 2 - we're in Isolate ${Isolate.current.debugName}"));
  final coroutineThree = launch(() => print("From Coroutine 3 - we're in Isolate ${Isolate.current.debugName}"));

  await Future.wait([
    coroutineOne.result,
    coroutineTwo.result,
    coroutineThree.result,
  ]);
  exit(0);
}