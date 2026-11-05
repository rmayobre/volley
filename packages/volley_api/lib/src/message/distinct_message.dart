import 'package:meta/meta.dart';

import '../uuid/uuid_v4.dart';
import 'message.dart';

@immutable
mixin DistinctMessage implements Message {
  final String id = uuidV4();
}
