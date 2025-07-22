import 'dart:async';

import 'disposable.dart';
import 'disposable_subscription.dart';
import 'disposables.dart';

extension DisposablesBuilder on Iterable<Disposables> {

  Disposable asDisposable() => Disposables(this);
}

extension DisposableSubscriptionBuilder<T> on StreamSubscription<T> {

  Disposable asDisposable() => DisposableSubscription(this);
}