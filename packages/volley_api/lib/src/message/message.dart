import 'package:meta/meta.dart';

/// Marker interface for everything that can travel through a `Channel`.
///
/// Messages are immutable and must be cloneable across isolates (or
/// `postMessage` on the web): use primitives, collections, typed data and
/// other messages, but not closures, sockets or ports. Violations surface as
/// an `UnsendableMessageException`.
@immutable
abstract interface class Message {
}
