import 'dart:async';

import 'package:volley_api/volley_api.dart';

Future<Actor<I, O>> actor<I extends Message, O extends Message>(
  FutureOr<O> Function(I) reducer,
) => throw UnimplementedError('Actor is not supported on this platform.');
