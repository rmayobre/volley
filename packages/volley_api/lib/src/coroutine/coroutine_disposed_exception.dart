final class CoroutineDisposedException implements Exception {
  const CoroutineDisposedException();

  @override
  String toString() =>
      'CoroutineDisposedException: coroutine was disposed before completion';
}
