import 'dart:async';

import 'coroutine.dart';
import '../pool/base_pool.dart';
import '../pool/pool.dart';
import 'agent.dart';
import 'io/isolate_agent.dart';

final class AgentPool extends BasePool<Agent> {
  AgentPool(int size) : super(size, (index) => IsolateAgent.spawn(name: 'Agent-$index'));

  Coroutine<R> launch<R>(Computation<R> compute) => _Coroutine(this, compute);
}

final class _Coroutine<R> implements Coroutine<R> {

  final completer = Completer<R>();

  final AgentPool pool;

  @override
  Future<R> get result => completer.future;

  _Coroutine(this.pool, Computation<R> compute) {
    withResource(pool, (agent) {
      try {
        final result = agent.compute(compute);
        completer.complete(result);
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
  }

  @override
  void dispose() {
    // TODO implement a way to cancel a coroutine.
    // Try a poison-pill method.
  }
}