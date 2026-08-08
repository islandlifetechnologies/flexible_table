import 'dart:math';

import 'package:flexible_table/flexible_table.dart';
import 'package:flutter/foundation.dart';

/// Defines a single row of data within a [FlexTable].
@immutable
class FlexTableRow {
  /// Creates the row with the data for the [columns] of the row.  The optional
  /// [key] can be provided to give hints to the [FlexTable] for rebuilds and
  /// the default is simply a [UniqueKey] to that every row has a unique [key].
  FlexTableRow({required this.columns, Key? key})
    : key = key ?? Random().nextDouble().toString();

  /// The columns for the row.  This will be detached from the list passed to
  /// the constructor and will always be unmodifiable.
  final List<FlexTableCell> columns;

  /// The key to use for the widget that ultimately builds the row.
  final Object key;
}
