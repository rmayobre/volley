import 'package:meta/meta.dart';
import 'package:volley_api/volley_api.dart';

@internal
sealed class SingletonResult implements Message {}

@internal
final class SingletonConstructed
    with DistinctMessage
    implements SingletonResult {}

@internal
final class SingletonResponse<I extends Message>
    with DistinctMessage
    implements SingletonResult {
  final I response;

  SingletonResponse(this.response);
}
