import 'dart:async';
import 'dart:isolate';

import 'package:meta/meta.dart';

import '../../volley.dart';
import '../actor.dart';
import '../spawn.dart';

@immutable
final class IsolateBundle<I extends Object, O extends Object> {

  final String id;
  final SendPort sendPort;
  final ActorFactory<I, O> _create;

  late final Actor<I, O> _actor;

  IsolateBundle({
    required this.id,
    required this.sendPort,
    required ActorFactory<I, O> create
  }) : _create = create;


  void initActor() {
    Volley.init(id: id);
    _actor = _create();
  }

  FutureOr<O>? reduce(dynamic message) {
    if (message is I) {
      return _actor.handleMessage(message);
    } else {
      return null;
    }
  }
}