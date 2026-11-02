import 'ingress_channel.dart';
import 'egress_channel.dart';
import '../message/message.dart';

@pragma('vm:isolate-unsendable')
abstract interface class Channel<I extends Message, O extends Message>
    implements IngressChannel<I>, EgressChannel<O> {}
