import '../message/message.dart';

/// The sending half of a [Channel].
abstract interface class EgressChannel<O extends Message> {
  /// Sends [message] to the other end.
  ///
  /// Throws an `UnsendableMessageException` if the message cannot be cloned
  /// across the isolate/worker boundary.
  void send(O message);
}
