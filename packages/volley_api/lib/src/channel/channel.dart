import 'ingress_channel.dart';
import 'egress_channel.dart';
import '../message/message.dart';

/// A two-way message conduit.
///
/// [I] is what this end *receives* ([messages]) and [O] is what it *sends*
/// ([send]). The opposite end sees the type parameters swapped. A channel
/// cannot itself be sent across isolates.
@pragma('vm:isolate-unsendable')
abstract interface class Channel<I extends Message, O extends Message>
    implements IngressChannel<I>, EgressChannel<O> {}
