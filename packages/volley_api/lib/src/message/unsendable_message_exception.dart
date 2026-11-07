/// Thrown when a [Message] could not be sent because its runtime value is
/// not safely cloneable across an isolate or web worker boundary.
///
/// This is a runtime safety net: messages declared with `@encodable`
/// (see `package:volley_workers_gen`) are already checked for this at build
/// time, so this exception is expected to surface mainly for hand-written
/// [Message] classes that skip that check, or for fields whose static type
/// (e.g. `dynamic`) couldn't be verified ahead of time.
final class UnsendableMessageException implements Exception {
  /// The runtime type of the message that failed to send.
  final Type messageType;

  /// The underlying platform error (e.g. an `ArgumentError` from
  /// `SendPort.send`, or a JS interop error from `jsify()`/`postMessage`).
  final Object cause;

  const UnsendableMessageException(this.messageType, this.cause);

  @override
  String toString() =>
      'UnsendableMessageException: a $messageType could not be sent — its '
      'runtime value is not safely cloneable on this platform. If it was '
      'declared with @encodable, run `dart run build_runner build` to '
      'catch this at build time instead.\nUnderlying error: $cause';
}
