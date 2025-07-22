# Volley

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/logo-dark.svg">
  <img alt="Dart volley" src="assets/logo-light.svg" height=300 />
</picture>

A concurrency framework built on top of existing Dart IO tools such as: Isolates, Zones, and Micro-tasking (soon 
WebWorks). The goal of this framework is to provide scalable tooling around the existing Dart tools built for 
concurrency.

## How to use Actors

```dart
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
```

### Example Output

```
Received message: hello
Received response: Responding to hello
Received message: world
Received response: Responding to world
```

## How to use Coroutines

```dart
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
```

### Example Output

```
From Coroutine 1 - we're in Isolate Agent-1
From Coroutine 3 - we're in Isolate Agent-3
From Coroutine 2 - we're in Isolate Agent-2
```

# Features

- Isolate Support
- Actor Concurrency Model
- Coroutine Concurrency Model
  - Should NOT be used within Actors (still optimizing)
  - Currently does NOT support nested Coroutines (fix WIP)
  - Currently does NOT support `MessageBus` (fix WIP)
- Resource Pooling
- Resource Disposal
  - Builders for native dart structures
- Global Messaging between Actors/Isolates via `MessageBus`
  - Currently NOT supported with Coroutines.