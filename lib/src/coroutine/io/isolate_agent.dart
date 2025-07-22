import 'dart:async';
import 'dart:isolate';

import '../agent.dart';
import '../compute_result.dart';

final class IsolateAgent implements Agent {
  
  final Isolate _isolate;
  final ReceivePort _receivePort;
  final SendPort _sendPort;
  
  IsolateAgent(this._isolate, this._receivePort, this._sendPort);

  static Future<IsolateAgent> spawn({String? name}) async {
    final firstResponse = Completer();
    final rawPort = RawReceivePort((message) => firstResponse.complete(message));
    final isolate = await Isolate.spawn(_entryPoint, rawPort.sendPort, debugName: name);
    final sendPort = await firstResponse.future as SendPort;
    final receivePort = ReceivePort.fromRawReceivePort(rawPort);
    return IsolateAgent(isolate, receivePort, sendPort);
  }


  @override
  Future<R> compute<R>(Computation<R> computation) async {
    final port = ReceivePort();
    _sendPort.send(Task(responsePort: port.sendPort, compute: computation));
    return await port.first
        .then((response) => response as CoroutineResult)
        .then((result) {
          switch (result) {
            case SuccessfulComputation():
              return result.value;
            case FailedComputation():
              throw result.error;
          }
        });
  }

  @override
  void dispose() {
    _receivePort.close();
    _isolate.kill(priority: Isolate.immediate);
  }

}

void _entryPoint(SendPort sendPort) async {
  final receivePort = ReceivePort();
  final controller = StreamController(sync: true)..addStream(receivePort);
  final incomingTask = controller.stream
    .where((message) => message is Task)
    .cast<Task>();
  sendPort.send(receivePort.sendPort);
  await for (final task in incomingTask) {
    try {
      final result = await task.compute();
      task.responsePort.send(SuccessfulComputation(result));
    } catch (error, stackTrace) {
      task.responsePort.send(FailedComputation(error, stackTrace));
    }
  }
}

final class Task {
  
  final SendPort responsePort;
  final Computation compute;
  
  const Task({required this.responsePort, required this.compute});
}