// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

List<E> freezeInDevMode<E>(List<E> list) {
  if (list == null) return const [];
  assert(() {
    list = new List<E>.unmodifiable(list);
    return true;
  }());
  return list;
}
