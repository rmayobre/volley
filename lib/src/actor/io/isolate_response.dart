import 'package:meta/meta.dart';

@immutable
sealed class IsolateMessage {}

final class IsolateResponse implements IsolateMessage {

  final dynamic value;

  const IsolateResponse(this.value);
}

final class IsolateError implements IsolateMessage {

  final Object error;
  final StackTrace? stackTrace;

  const IsolateError(this.error, [this.stackTrace]);
}