import 'package:volley_api/volley_api.dart';

final class CoroutineResult<R> implements DistinctMessage {
  @override
  final String id;
  final R? value;
  final bool isCancelled;

  const CoroutineResult(this.id, R this.value) : isCancelled = false;

  const CoroutineResult.cancelled(this.id) : value = null, isCancelled = true;
}
