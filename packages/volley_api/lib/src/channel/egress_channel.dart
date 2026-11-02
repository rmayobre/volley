import '../message/message.dart';

abstract interface class EgressChannel<O extends Message> {
  void send(O message);
}
