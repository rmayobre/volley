sealed class CoroutineResult {}

final class SuccessfulComputation<R> implements CoroutineResult {

  final dynamic value;

  const SuccessfulComputation(this.value);
}

final class FailedComputation<R> implements CoroutineResult {

  final Object error;
  final StackTrace? stackTrace;

  FailedComputation(this.error, [this.stackTrace]);
}