import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:volley_api/volley_api.dart';

@internal
sealed class SingletonResult implements Message {}

@internal
final class SingletonConstructed
    with DistinctMessage
    implements SingletonResult {}

@internal
final class SingletonStopped with DistinctMessage implements SingletonResult {}

/// A [Singleton] failed to build or to handle a message.
///
/// Reported to the caller instead of being thrown, so that one failing
/// singleton can't take down the shared singleton isolate.
@internal
final class SingletonFailure with DistinctMessage implements SingletonResult {
  final Object error;

  /// The stack trace of [error], as text (stack traces aren't sendable).
  final String stackTrace;

  SingletonFailure(this.error, this.stackTrace);

  /// The same failure with [error] replaced by a text description, for when
  /// the original error object can't cross the isolate boundary.
  SingletonFailure asRemoteError() =>
      SingletonFailure(RemoteError(error.toString(), stackTrace), stackTrace);
}

@internal
final class SingletonResponse<I extends Message>
    with DistinctMessage
    implements SingletonResult {
  final I response;

  SingletonResponse(this.response);
}
