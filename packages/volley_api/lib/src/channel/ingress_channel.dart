import 'dart:async';

import 'channel.dart';
import '../message/message.dart';

abstract interface class IngressChannel<I extends Message> {
  const factory IngressChannel(Channel<I, dynamic> channel) = _ReadOnlyChannel;

  Stream<I> get messages;
}

final class _ReadOnlyChannel<I extends Message> implements IngressChannel<I> {
  final Channel<I, dynamic> _channel;

  const _ReadOnlyChannel(Channel<I, dynamic> channel) : _channel = channel;

  @override
  Stream<I> get messages => _channel.messages;
}

extension ChannelExtensions<I extends Message> on Channel<I, dynamic> {
  IngressChannel<I> asIngress() => _ReadOnlyChannel<I>(this);
}
