import 'package:meta/meta.dart';

import '../uuid/uuid_v4.dart';
import 'message.dart';

/// Mixin giving a [Message] a unique, randomly generated [id] (a UUIDv4).
///
/// The id is assigned when the instance is constructed, which lets receivers
/// correlate requests with responses or deduplicate deliveries.
@immutable
mixin DistinctMessage implements Message {
  /// Unique identifier of this message instance.
  final String id = uuidV4();
}
