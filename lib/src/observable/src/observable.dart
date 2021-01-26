// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observable.src.observable;

import 'dart:async';

import 'package:meta/meta.dart';

import 'change_notifier.dart';
import 'records.dart';

/// Represents an object with observable state or properties.
///
/// The interface does not require any specific technique to implement
/// observability. You may implement it in the following ways:
/// - Extend or mixin [ChangeNotifier]
/// - Implement the interface yourself and provide your own implementation
abstract class Observable<C extends ChangeRecord> {
  // To be removed when https://github.com/dart-lang/observable/issues/10
  final ChangeNotifier<C> _delegate = ChangeNotifier<C>();

  /// Emits a list of changes when the state of the object changes.
  ///
  /// Changes should produced in order, if significant.
  Stream<List<C>?> get changes => _delegate.changes;

  /// May override to be notified when [changes] is first observed.
  @protected
  @mustCallSuper
  @Deprecated('Use ChangeNotifier instead to have this method available')
  // REMOVE IGNORE when https://github.com/dart-lang/observable/issues/10
  void observed() => _delegate.observed();

  /// May override to be notified when [changes] is no longer observed.
  @protected
  @mustCallSuper
  @Deprecated('Use ChangeNotifier instead to have this method available')
  // REMOVE IGNORE when https://github.com/dart-lang/observable/issues/10
  void unobserved() => _delegate.unobserved();

  /// True if this object has any observers.
  @Deprecated('Use ChangeNotifier instead to have this method available')
  bool get hasObservers => _delegate.hasObservers;

  /// If [hasObservers], synchronously emits [changes] that have been queued.
  ///
  /// Returns `true` if changes were emitted.
  @Deprecated('Use ChangeNotifier instead to have this method available')
  // REMOVE IGNORE when https://github.com/dart-lang/observable/issues/10
  bool deliverChanges() => _delegate.deliverChanges();

  /// Schedules [change] to be delivered.
  ///
  /// If [change] is omitted then [ChangeRecord.any] will be sent.
  ///
  /// If there are no listeners to [changes], this method does nothing.
  @Deprecated('Use ChangeNotifier instead to have this method available')
  void notifyChange([C? change]) => _delegate.notifyChange(change);
}
