import 'dart:async';

import 'package:meta/meta.dart';
import 'package:volley_api/volley_api.dart';

import '../../channel/web/web_stream_channel.dart';

/// An [Actor] that runs the handler on the main thread.
///
/// Obtain an instance via the [actor] function.
@internal
final class WebActor<I extends Message, O extends Message>
    implements Actor<I, O> {
  @override
  final WebStreamChannel<I, O> channel;

  final _closed = Completer<Object?>();

  WebActor(this.channel);

  @override
  Future<Object?> get closed => _closed.future;

  @override
  Future<void> dispose() async {
    await channel.dispose();
    if (!_closed.isCompleted) _closed.complete(null);
  }
}
