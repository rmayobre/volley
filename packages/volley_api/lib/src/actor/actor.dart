import '../channel/channel.dart';
import '../message/message.dart';
import '../disposable/disposable.dart';

@pragma('vm:isolate-unsendable')
abstract interface class Actor<I extends Message, O extends Message>
    implements Disposable {
  /// The caller's end of the actor.
  ///
  /// Follows [Channel]'s convention: [I] is the ingress (what the caller
  /// *receives* from the actor) and [O] is the egress (what the caller
  /// *sends* to the actor). The actor's reducer is therefore
  /// `FutureOr<I> Function(O)`: it consumes [O] and produces [I].
  Channel<I, O> get channel;

  /// Completes when this actor has closed, for any reason.
  ///
  /// The value is `null` when the actor closed normally (e.g. via [dispose]),
  /// or the error that the actor failed with when it was closed by an
  /// uncaught exception (similar to `Isolate.addOnExitListener` /
  /// `addErrorListener`). The future itself never completes with an error, so
  /// it is always safe to `await`.
  ///
  /// An actor that hits an uncaught exception (e.g. its reducer throws)
  /// closes itself and stops processing messages.
  Future<Object?> get closed;
}
