/// Thrown by `Pool.execute` when the pool was disposed, either before the call
/// or while the call was still waiting for a free resource.
final class PoolDisposedException implements Exception {
  const PoolDisposedException();

  @override
  String toString() => 'PoolDisposedException: the pool has been disposed';
}
