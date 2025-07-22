import 'dart:async';

import '../disposable/disposable.dart';

/// Represents an asynchronous two-way communication between a sender and receiver.
abstract interface class Mailbox<I extends Object, O extends Object>
    implements Stream<O>, Disposable {

  bool get isOpen;

  void send(I message);
}