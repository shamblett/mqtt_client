// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observable.src.records;

/// Result of a change to an observed object.
class ChangeRecord {
  /// Constructor
  const ChangeRecord();

  /// Signifies a change occurred, but without details of the specific change.
  ///
  /// May be used to produce lower-GC-pressure records where more verbose change
  /// records will not be used directly.
  static const List<ChangeRecord> any = <ChangeRecord>[ChangeRecord()];

  /// Signifies no changes occurred.
  static const List<ChangeRecord> none = <ChangeRecord>[];
}
