import 'dart:async';

import 'channel.dart';
import '../message/message.dart';

/// The receiving half of a [Channel].
abstract interface class IngressChannel<I extends Message> {
  /// A read-only view of [channel] that hides its sending half.
  const factory IngressChannel(Channel<I, dynamic> channel) = _ReadOnlyChannel;

  /// The messages received from the other end.
  Stream<I> get messages;
}

final class _ReadOnlyChannel<I extends Message> implements IngressChannel<I> {
  final Channel<I, dynamic> _channel;

  const _ReadOnlyChannel(Channel<I, dynamic> channel) : _channel = channel;

  @override
  Stream<I> get messages => _channel.messages;
}

/// Extensions on [Channel].
extension ChannelExtensions<I extends Message> on Channel<I, dynamic> {
  /// Returns a view of this channel that can only receive.
  IngressChannel<I> asIngress() => _ReadOnlyChannel<I>(this);
}
