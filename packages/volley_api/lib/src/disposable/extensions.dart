import 'disposable.dart';
import 'disposable_subscription.dart';
import 'disposables.dart';
import 'dart:async';

/// Groups many [Disposable]s into one.
extension DisposablesBuilder on Iterable<Disposable> {
  Disposable asDisposable() => Disposables(this);
}

/// Adapts a [StreamSubscription] to [Disposable].
extension DisposableSubscriptionBuilder<T> on StreamSubscription<T> {
  DisposableSubscription<T> asDisposable() => DisposableSubscription(this);
}
