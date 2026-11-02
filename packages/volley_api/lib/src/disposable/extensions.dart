import 'disposable.dart';
import 'disposable_subscription.dart';
import 'disposables.dart';
import 'dart:async';

extension DisposablesBuilder on Iterable<Disposable> {
  Disposable asDisposable() => Disposables(this);
}

extension DisposableSubscriptionBuilder<T> on StreamSubscription<T> {
  DisposableSubscription<T> asDisposable() => DisposableSubscription(this);
}
