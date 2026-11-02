import 'dart:async';
import 'dart:isolate';

import '../init/io/bootstrapper.dart';
import '../singleton/singleton.dart';
import '../singleton/io/singleton_send_port.dart';
import 'coroutine_message.dart';
import 'coroutine_result.dart';

final class CoroutineExecutor
    implements Singleton<CoroutineMessage, CoroutineResult> {
  final _activeJobs = <String, (Isolate, ReceivePort)>{};
  final _pendingCancels = <String>{};

  @override
  Future<CoroutineResult<dynamic>> reduce(CoroutineMessage message) async {
    switch (message) {
      case CoroutineDisposal():
        final job = _activeJobs.remove(message.id);
        if (job != null) {
          final (subIsolate, resultPort) = job;
          subIsolate.kill(priority: Isolate.immediate);
          // Closing the port makes any pending resultPort.first throw StateError,
          // unblocking the task's reduce() so it can return a cancelled result.
          resultPort.close();
        } else {
          _pendingCancels.add(message.id);
        }
        return CoroutineResult.cancelled(message.id);

      case CoroutineTask():
        if (_pendingCancels.remove(message.id)) {
          return CoroutineResult.cancelled(message.id);
        }

        final resultPort = ReceivePort();
        final subIsolate = await Isolate.spawn(
          _runInSubIsolate,
          _SubIsolateArgs(
            message.compute,
            resultPort.sendPort,
            singletonSendPort,
          ),
        );

        // A CoroutineDisposal may have arrived while spawning was in-flight.
        if (_pendingCancels.remove(message.id)) {
          subIsolate.kill(priority: Isolate.immediate);
          resultPort.close();
          return CoroutineResult.cancelled(message.id);
        }

        _activeJobs[message.id] = (subIsolate, resultPort);

        try {
          final raw = await resultPort.first;
          subIsolate.kill();
          resultPort.close();
          _activeJobs.remove(message.id);
          if (raw is _ComputationError) {
            // ignore: only_throw_errors
            throw raw.error;
          }
          return CoroutineResult(message.id, raw);
        } on StateError {
          // resultPort was closed by the CoroutineDisposal handler before the
          // sub-isolate sent a result — treat this as a successful cancellation.
          _activeJobs.remove(message.id);
          return CoroutineResult.cancelled(message.id);
        } catch (e) {
          _activeJobs.remove(message.id);
          rethrow;
        }
    }
  }
}

/// Entry point executed inside each per-job sub-isolate.
@pragma('vm:entry-point')
void _runInSubIsolate(_SubIsolateArgs args) async {
  // Bootstrap the sub-isolate so that nested coroutine() calls work.
  singletonSendPort = args.singletonPort;
  await Bootstrapper.initialize();
  try {
    args.resultPort.send(await args.compute());
  } catch (e, st) {
    args.resultPort.send(_ComputationError(e, st));
  }
}

final class _SubIsolateArgs {
  final FutureOr<dynamic> Function() compute;
  final SendPort resultPort;
  final SendPort? singletonPort;

  const _SubIsolateArgs(this.compute, this.resultPort, this.singletonPort);
}

final class _ComputationError {
  final Object error;
  final StackTrace stackTrace;

  const _ComputationError(this.error, this.stackTrace);
}
