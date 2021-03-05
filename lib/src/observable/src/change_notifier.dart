import 'dart:async';

import 'package:meta/meta.dart';

import 'observable.dart';
import 'records.dart';

/// Supplies [changes] and various hooks to implement [Observable].
///
/// May use [notifyChange] to queue a change record; they are asynchronously
/// delivered at the end of the VM turn.
///
/// [ChangeNotifier] may be extended, mixed in, or used as a delegate.
class ChangeNotifier<C extends ChangeRecord> implements Observable<C> {
  late StreamController<List<C>> _changes;

  bool _scheduled = false;
  List<C>? _queue;

  /// Emits a list of changes when the state of the object changes.
  ///
  /// Changes should produced in order, if significant.
  @override
  Stream<List<C>> get changes =>
      (_changes = StreamController<List<C>>.broadcast(
        sync: true,
        onListen: observed,
        onCancel: unobserved,
      ))
          .stream;

  /// May override to be notified when [changes] is first observed.
  @override
  @mustCallSuper
  void observed() {}

  /// May override to be notified when [changes] is no longer observed.
  @override
  @mustCallSuper
  void unobserved() {
    _changes.close();
  }

  /// If [hasObservers], synchronously emits [changes] that have been queued.
  ///
  /// Returns `true` if changes were emitted.
  @override
  @mustCallSuper
  bool deliverChanges() {
    List<C> changes;
    if (_scheduled && hasObservers) {
      changes = ChangeRecord.any as List<C>;
      _scheduled = false;
      _changes.add(changes);
      return true;
    }
    return false;
  }

  /// Whether [changes] has at least one active listener.
  ///
  /// May be used to optimize whether to produce change records.
  @override
  bool get hasObservers => _changes.hasListener == true;

  /// Schedules [change] to be delivered.
  ///
  /// If [change] is omitted then [ChangeRecord.any] will be sent.
  ///
  /// If there are no listeners to [changes], this method does nothing.
  @override
  void notifyChange([C? change]) {
    if (!hasObservers) {
      return;
    }
    if (change != null) {
      (_queue ??= <C>[]).add(change);
    }
    if (!_scheduled) {
      scheduleMicrotask(deliverChanges);
      _scheduled = true;
    }
  }
}
