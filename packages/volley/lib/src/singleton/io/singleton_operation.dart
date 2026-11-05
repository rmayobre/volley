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

@internal
final class SingletonMessage<O extends Message>
    with DistinctMessage
    implements SingletonOperation {
  final Type singletonType;
  final O message;
  final SendPort? replyTo;

  SingletonMessage(this.singletonType, this.message, {this.replyTo});
}
