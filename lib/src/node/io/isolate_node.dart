import '../../bus/base_message_bus.dart';
import '../../bus/message_bus.dart';
import '../node.dart';
import '../node_ref.dart';

final class IsolateNode implements Node {

  @override
  final String id;

  @override
  final MessageBus bus = BaseMessageBus();

  final Map<String, NodeRef> children = {};

  @override
  int get childCount => children.length;

  IsolateNode({required this.id});

  @override
  NodeRef? child(String id) => children[id];

  @override
  void register(NodeRef child) {
    children[child.id] = child;
    // Forward all MessageBus messages to child.
    final subscription = bus.messages().listen(child.send);
    child.done.then((value) {
      subscription.cancel(); // Stop sending messages when child is destroyed.
      // Do NOT remove child from map. The child count is important for ID creation.
    });
  }
}