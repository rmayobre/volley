import 'dart:async';

import 'package:meta/meta.dart';
import 'package:volley/volley.dart' show Singleton;
import 'package:volley_api/volley_api.dart';

/// Serves one worker request: takes the request in wire form, returns the
/// reply in wire form.
typedef SingletonHandler = Future<Object?> Function(Object? request);

final _handlers = <String, SingletonHandler>{};

/// Makes a singleton reachable from web workers under [key].
///
/// Generated `register<Name>()` functions call this; call them on the page
/// before spawning workers that use the singleton (spawn/launch functions in
/// the same library do it for you). Registering twice is harmless.
///
/// [decodeIn] and [encodeOut] convert between the wire form that crosses the
/// worker boundary and the singleton's message types.
void registerSingleton<
  I extends Message,
  O extends Message,
  T extends Singleton<I, O>
>({
  required String key,
  required T Function() build,
  required O Function(Object? wire) decodeIn,
  required Object? Function(I message) encodeOut,
}) {
  _handlers.putIfAbsent(
    key,
    () =>
        (wire) async =>
            encodeOut(await Singleton.request<I, O, T>(build, decodeIn(wire))),
  );
}

/// The handler registered under [key], if any.
@internal
SingletonHandler? lookupSingleton(String key) => _handlers[key];
