import 'dart:math';

import 'package:flexible_table/flexible_table.dart';
import 'package:flutter/foundation.dart';

/// Defines a single row of data within a [FlexTable].
class FlexTableRow({required final List<FlexTableCell> columns, Key? key}) {
  this : key = key ?? Random().nextDouble().toString();

  /// The key to use for the widget that ultimately builds the row.
  final Object key;
}
