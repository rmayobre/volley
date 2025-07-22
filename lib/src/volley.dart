import 'node/node.dart';

final class Volley {

  static void init({String id = 'MainNode'}) {
    instance = Node(id: id);
  }
}