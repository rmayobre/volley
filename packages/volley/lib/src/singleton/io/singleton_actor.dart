import 'package:meta/meta.dart';
import 'package:volley_api/volley_api.dart';

import '../../actor/actor.dart';
import '../singleton.dart';
import 'singleton_operation.dart';
import 'singleton_results.dart';

final _singletons = <Type, Singleton<dynamic, dynamic>>{};

@internal
Future<Actor<SingletonOperation, SingletonResult>> spawnSingletonActor() {
  return actor<SingletonOperation, SingletonResult>((message) async {
    switch (message) {
      case SingletonInit<Singleton<Message, Message>>():
        _singletons.putIfAbsent(message.singletonType, message.build);
        final constructed = SingletonConstructed();
        message.replyTo?.send(constructed);
        return constructed;
      case SingletonMessage():
        final singleton = _singletons[message.singletonType];
        if (singleton == null)
          throw StateError(
            'Singleton ${message.singletonType} is not registered',
          );
        final result = await singleton.reduce(message.message);
        final response = SingletonResponse(result as Message);
        message.replyTo?.send(response);
        return response;
    }
  });
}
