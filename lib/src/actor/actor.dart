import 'dart:async';

abstract interface class Actor<I, O> {

  FutureOr<O> handleMessage(I message);

}