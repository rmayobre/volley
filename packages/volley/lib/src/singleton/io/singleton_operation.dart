import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:volley_api/volley_api.dart';

import '../singleton.dart';

@internal
sealed class SingletonOperation implements Message {}

@internal
final class SingletonInit<T extends Singleton<Message, Message>>
    with DistinctMessage
    implements SingletonOperation {
  final Type singletonType;
  final T Function() build;
  final SendPort? replyTo;

  SingletonInit(this.singletonType, this.build, {this.replyTo});
}

/// Asks the host to dispose every singleton that is [Disposable] and then
/// confirm with [SingletonStopped]. Sent by `Bootstrapper.shutdown()`.
@internal
final class SingletonShutdown
    with DistinctMessage
    implements SingletonOperation {
  final SendPort? replyTo;

  SingletonShutdown({this.replyTo});
}

@internal
final class SingletonMessage<O extends Message>
    with DistinctMessage
    implements SingletonOperation {
  final Type singletonType;
  final O message;
  final SendPort? replyTo;

  SingletonMessage(this.singletonType, this.message, {this.replyTo});
}
