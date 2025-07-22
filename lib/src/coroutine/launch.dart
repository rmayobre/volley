import 'dart:io';

import '../../volley.dart';

final agents = AgentPool(Platform.numberOfProcessors);

Coroutine<R> launch<R>(Computation<R> compute) => agents.launch(compute);