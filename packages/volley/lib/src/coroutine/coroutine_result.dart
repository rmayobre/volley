import 'package:volley_api/volley_api.dart';

/// The outcome of a [CoroutineTask]: a [value], a failure ([error]), or a
/// cancellation.
///
/// Must stay sendable across isolates, so a failure carries the stack trace
/// as text rather than a `StackTrace` object.
final class CoroutineResult<R> implements DistinctMessage {
  @override
  final String id;
  final R? value;
  final bool isCancelled;

  /// The error the computation threw, if it failed.
  final Object? error;

  /// The stack trace of [error], as text.
  final String? stackTrace;

  const CoroutineResult(this.id, R this.value)
    : isCancelled = false,
      error = null,
      stackTrace = null;

  const CoroutineResult.cancelled(this.id)
    : value = null,
      isCancelled = true,
      error = null,
      stackTrace = null;

  const CoroutineResult.failed(this.id, Object this.error, this.stackTrace)
    : value = null,
      isCancelled = false;

  bool get isFailed => error != null;
}
