/// Completes a `Coroutine.result` that was disposed before it finished.
final class CoroutineDisposedException implements Exception {
  /// Creates the exception.
  const CoroutineDisposedException();

  @override
  String toString() =>
      'CoroutineDisposedException: coroutine was disposed before completion';
}
