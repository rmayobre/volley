import '../bus/message_bus.dart';
import 'io/isolate_node.dart';
import 'node_ref.dart';

Node? _instance;

set instance(Node node) {
  if (_instance != null) throw StateError('Volley has already been initialized');
  _instance = node;
}

/// A unit of computation. Used to help isolate memory and processing with the
/// intent to keep stability between parallel computations.
abstract interface class Node {

  /// A unique identifier for the [Node]. This should be unique across the entire
  /// lifespan of the running application.
  String get id;

  /// The [MessageBus] assigned to the Node instance.
  MessageBus get bus;

  /// Number of children in Node.
  int get childCount;

  factory Node({required String id}) => IsolateNode(id: id);

  /// Get the current instance of the [Node] in this code's memory. [Node]s are
  /// separate in memory. Depending on where the caller of this getter is, there
  /// will be a different;
  static Node get current {
    final instance = _instance;
    if (instance == null) throw StateError('Node needs to be initialized.');
    return instance;
  }

  /// Get child reference from this [Node]. Returns null if child is not registered
  /// or identifiable by this node.
  NodeRef? child(String id);

  /// Registers a [NodeRef] to this [Node].
  void register(NodeRef child);
}