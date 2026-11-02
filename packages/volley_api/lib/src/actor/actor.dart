import '../channel/channel.dart';
import '../message/message.dart';
import '../disposable/disposable.dart';

@pragma('vm:isolate-unsendable')
abstract interface class Actor<I extends Message, O extends Message>
    implements Disposable {
  Channel<I, O> get channel;
}
