import 'dart:async';

import 'package:volley_api/volley_api.dart';

/// Creates an [Actor]. Not supported on this platform: always throws
/// [UnimplementedError]. The real implementations are selected by conditional
/// export on `dart:io` and `dart:js_interop` platforms.
Future<Actor<I, O>> actor<I extends Message, O extends Message>(
  FutureOr<I> Function(O) reducer,
) => throw UnimplementedError('Actor is not supported on this platform.');
