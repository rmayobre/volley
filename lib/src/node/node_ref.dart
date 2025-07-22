import '../disposable/disposable.dart';
import 'node.dart';

/// Reference to a [Node] instance. Used to help maintain a two-way communication
/// between the instance and the reference. Helps reflect state and messaging in
/// a concurrent setting.
abstract interface class NodeRef implements Disposable {

  /// Generates a unique id for a [NodeRef].
  static String createId() => '${Node.current.id}-${Node.current.childCount + 1}';

  /// A unique identifier for the [Node]. This should be unique across the entire
  /// lifespan of the running application.
  String get id;

  /// Has the node been disposed (the [dispose] function called)?
  /// or has the node errored out?
  bool get isDisposed;

  /// Helps determine when the [Node] has been disposed or killed from an error.
  Future get done;

  /// Send a message directly to the node.
  void send(Object message);
}
