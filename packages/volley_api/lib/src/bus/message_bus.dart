import 'dart:async';

/// A typed publish/subscribe hub.
///
/// Subscribers select messages by runtime type, so one bus can carry unrelated
/// message types. See [BaseMessageBus] for the standard implementation.
abstract interface class MessageBus {
  /// Publishes [message] to every subscriber whose requested type matches it.
  void publish<M extends Object>(M message);

  /// A stream of every published message that is an [M].
  Stream<M> messages<M extends Object>();
}
