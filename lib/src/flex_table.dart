import 'dart:async';
import 'dart:math';

import 'package:flexible_table/flexible_table.dart';
import 'package:material_ui/material_ui.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:popover/popover.dart';
import 'package:provider/provider.dart';

/// A type definition for a function that can perform a filter.  This function
/// should return [true] when a value should be filtered (removed) from the
/// result set and [false] if the value should remain in the result set.
typedef FlexTableFilterer = bool Function(String filter, String value);

/// A type definition for a function that can perform value sorting.  The
/// returned value must be 0 if the values are considered equal, <0 if the
/// [a] value is less than the [b] value and >0 if the [a] value is greater than
/// the [b] value.
typedef FlexTableSorter = int Function(bool ascending, String a, String b);

/// Builder for building any type of cell within the [FlexTable].  In general,
/// you will want to extend either the [FlexDataCellBuilder] or
/// [FlexHeaderCellBuilder] rather than this class as those are the two classes
/// required by the [FlexTable] itself.
///
/// See also
///   * [FlexDataCellBuilder]
///   * [FlexHeaderCellBuilder]
abstract class const FlexCellBuilder({
  final Alignment alignment = Alignment.centerLeft,
  final Color? color,
  final int maxLines = 1,
  final EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
    horizontal: 8.0,
  ),
  final Color? selectedColor,
}) {
  /// Builds the [Widget] for the cell located at [columnIndex] and [rowIndex].
  /// The passed in [child] should be wrapped by whatever widgets this builder
  /// provides.
  ///
  /// For headers, the [rowIndex] will always be -1.
  Widget build({
    required Widget child,
    required int columnIndex,
    required BuildContext context,
    required int rowIndex,
    required bool selected,
  }) {
    final theme = Theme.of(context);
    Widget result = Align(
      alignment: alignment,
      child: Padding(padding: padding, child: child),
    );

    final color = selected
        ? (selectedColor ??
              (theme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.25)))
        : this.color;

    if (color != null) {
      result = Material(color: color, child: result);
    }

    return result;
  }
}

/// Builder for data cells within the [FlexTable].  The default implementation
/// provides no additional functionality over the [FlexCellBuilder] and exists
/// solely so the header cells and data cells have fully distinct classes to
/// prevent accidental mix ups.
///
/// See also:
///   * [FlexStripeCellBuilder]
class const FlexDataCellBuilder({
  super.alignment,
  super.color,
  super.maxLines,
  super.padding,
  super.selectedColor,
}) extends FlexCellBuilder {}

/// Builds a divider between the table headers.  The divider is the draggable
/// portion that allows for resizing the columns.
class const FlexDefaultHeaderDividerBuilder({
  final Color? color,
  final Color? draggingColor,
  final Color? draggingIndicatorColor,
  final EdgeInsets draggingPadding = const EdgeInsets.symmetric(vertical: 4.0),
  final Color? hoverColor,
  final Color? hoverIndicatorColor,
  final EdgeInsets hoverPadding = const EdgeInsets.symmetric(vertical: 8.0),
  final Color? indicatorColor,
  final EdgeInsets padding = const EdgeInsets.symmetric(vertical: 12.0),
}) extends FlexHeaderDividerBuilder {
  this : super();

  /// Builds the section for the draggable divider.
  ///
  /// This conforms to the divider builder signature of the [MultiSplitView]
  /// though the default implementation does not actually make use of the
  /// [axis], [index], [resizable], nor the [themeData] attributes.  Only the
  /// [dragging] and [highlighted] values are used for building the cell and
  /// indicator.
  @override
  Widget build({
    required Axis axis,
    required BuildContext context,
    required bool dragging,
    required bool highlighted,
    required int index,
    required bool resizable,
    required MultiSplitViewThemeData themeData,
  }) {
    final theme = Theme.of(context);
    final textColor =
        theme.textTheme.bodyMedium?.color ??
        (theme.brightness == Brightness.light ? Colors.black : Colors.white);

    final color = this.color ?? Colors.transparent;
    final draggingColor =
        this.draggingColor ?? textColor.withValues(alpha: 0.24);
    final draggingIndicatorColor = this.draggingIndicatorColor ?? textColor;
    final hoverColor = this.hoverColor ?? textColor.withValues(alpha: 0.12);
    final hoverIndicatorColor =
        this.hoverIndicatorColor ?? textColor.withValues(alpha: 0.87);
    final indicatorColor =
        this.indicatorColor ?? textColor.withValues(alpha: 0.54);

    return ColoredBox(
      color: dragging
          ? draggingColor
          : highlighted
          ? hoverColor
          : color,
      child: Center(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 300),
          padding: dragging
              ? draggingPadding
              : highlighted
              ? hoverPadding
              : padding,
          child: SizedBox(
            height: double.infinity,
            width: 2.0,
            child: ColoredBox(
              color: dragging
                  ? draggingIndicatorColor
                  : highlighted
                  ? hoverIndicatorColor
                  : indicatorColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Builds a divider between the table headers.  The divider is the draggable
/// portion that allows for resizing the columns.
///
/// This is an abstract class that only provides the interface.  The default
/// implementation is the [FlexDefaultHeaderDividerBuilder].
abstract class const FlexHeaderDividerBuilder() {
  Widget build({
    required Axis axis,
    required BuildContext context,
    required bool dragging,
    required bool highlighted,
    required int index,
    required bool resizable,
    required MultiSplitViewThemeData themeData,
  });
}

/// Builder for data cells within the [FlexTable].  The default implementation
/// provides no additional functionality over the [FlexCellBuilder] and exists
/// solely so the header cells and data cells have fully distinct classes to
/// prevent accidental mix ups.
///
/// See also:
///   * [FlexFilterHeaderCellBuilder]
///   * [FlexSortHeaderCellBuilder]
class const FlexHeaderCellBuilder({
  super.alignment,
  super.color,
  super.maxLines,
  super.padding,
}) extends FlexCellBuilder {}

/// Controller to use to be able to filter by column values.  Be sure to
/// [dispose] the filter when it is no longer required to prevent memory leaks.
class FlexFilterController<F>({required final FlexTableController controller}) {
  final _controller = StreamController<void>.broadcast();

  int? _filterIndex;
  String? _filterValue;

  /// The current column index where a filter is being applied.  Will be if no
  /// filter is being applied.
  int? get filterIndex => _filterIndex;

  /// The current value of the filter being applied.  Will be null if no filter
  /// is being applied.
  String? get filterValue => _filterValue;

  /// Returns the [stream] that can be listened to.  The stream will have an
  /// event applied whenever the filter is changed.
  Stream<void> get stream => _controller.stream;

  /// Disposes the controller.
  void dispose() {
    _controller.close();
  }

  /// Updates the filter and applies it to the [FlexTable].  The [index] is the
  /// index of the column to apply the filter to and the [value] is the value to
  /// use when applying the filter.  Set both to null to remove the filter and
  /// cause the table to show all the rows.
  void update(int? index, String? value) {
    _filterIndex = index;
    _filterValue = value;

    _controller.add(null);
    controller.filter(index, value);
  }
}

/// Builder for [FlexTable] headers that utilize a popover to allow for
/// filtering the contents based on a particular value.
class const FlexFilterHeaderCellBuilder({
  super.alignment,
  super.color,
  required final FlexFilterController controller,
  final Icon icon = const Icon(
    Icons.filter_alt,
    color: Colors.black,
    size: 16.0,
  ),
  super.maxLines,
  super.padding,
}) extends FlexHeaderCellBuilder {
  @override
  Widget build({
    required Widget child,
    required int columnIndex,
    required BuildContext context,
    required int rowIndex,
    required bool selected,
  }) => Material(
    color: super.color,
    child: _FlexFilterHeaderCell(
      alignment: super.alignment,
      controller: controller,
      icon: icon,
      index: columnIndex,
      child: super.build(
        child: child,
        columnIndex: columnIndex,
        context: context,
        rowIndex: rowIndex,
        selected: selected,
      ),
    ),
  );
}

/// Controller for being able to sort rows by the values in a single column.
class FlexSortController({
  required final FlexTableController controller,
  final bool tristate = false,
}) {
  final _controller = StreamController<void>.broadcast();

  var _ascending = true;
  int? _columnIndex;

  /// Returns whether the list is sorted in ascending order (Z at the top, A at
  /// the bottom) or descending order (A at the top, Z at the bottom).
  bool get ascending => _ascending;

  /// Returns the column index to use for sorting.
  int? get columnIndex => _columnIndex;

  /// The event [stream] that can be listened to for when sort events are
  /// triggered.
  Stream<void> get stream => _controller.stream;

  /// Disposes the controller.
  void dispose() {
    _controller.close();
  }

  /// Updates the sort order for the [FlexTable].  If [index] is null, then
  /// sorting will be disabled.
  void update(int? index, bool ascending) {
    if (tristate) {
      if (index == _columnIndex && ascending == true) {
        index = null;
        ascending = true;
      }
    }

    _ascending = ascending;
    _columnIndex = index;

    _controller.add(null);

    controller.sort(index, ascending);
  }
}

/// Builder to build headers for a [FlexTable] that allow for sorting a column.
class const FlexSortHeaderCellBuilder({
  super.alignment,
  final Icon ascendingIcon = const Icon(
    Icons.arrow_downward,
    color: Colors.black,
    size: 16.0,
  ),
  super.color,
  required final FlexSortController controller,
  final Icon descendingIcon = const Icon(
    Icons.arrow_upward,
    color: Colors.black,
    size: 16.0,
  ),
  super.maxLines,
  super.padding,
}) extends FlexHeaderCellBuilder {
  @override
  Widget build({
    required Widget child,
    required int columnIndex,
    required BuildContext context,
    required int rowIndex,
    required bool selected,
  }) => Material(
    color: super.color,
    child: _FlexSortHeaderCell(
      alignment: super.alignment,
      ascendingIcon: ascendingIcon,
      controller: controller,
      descendingIcon: descendingIcon,
      index: columnIndex,
      child: super.build(
        child: child,
        columnIndex: columnIndex,
        context: context,
        rowIndex: rowIndex,
        selected: selected,
      ),
    ),
  );
}

/// Builder to use to build data cells that alternate in color by rows.
class const FlexStripeCellBuilder({
  super.alignment,
  final Color even = Colors.transparent,
  super.maxLines,
  final Color? odd,
  super.padding,
  super.selectedColor,
}) extends FlexDataCellBuilder {
  @override
  Widget build({
    required Widget child,
    required int columnIndex,
    required BuildContext context,
    required int rowIndex,
    required bool selected,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: rowIndex.isEven
          ? even
          : (odd ??
                (theme.brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05))),
      child: super.build(
        child: child,
        columnIndex: columnIndex,
        context: context,
        rowIndex: rowIndex,
        selected: selected,
      ),
    );
  }
}

/// Table that is higly performant regardless of the number of rows and allows
/// for fully resizable columns.
class const FlexTable({
  required final FlexTableController controller,
  final FlexDataCellBuilder dataBuilder = const FlexDataCellBuilder(),
  final double dataHeight = 40.0,
  final TextStyle? dataStyle,
  final WidgetBuilder? emptyDataBuilder,
  final FlexHeaderCellBuilder headerBuilder = const FlexHeaderCellBuilder(),
  final FlexHeaderDividerBuilder headerDividerBuilder =
      const FlexDefaultHeaderDividerBuilder(),
  final double headerHeight = 40.0,
  final TextStyle? headerStyle = const TextStyle(fontWeight: FontWeight.bold),
  required final List<FlexTableCell> headers,
  final List<FlexTableColumnSize>? initialColumnSizes,
  final List<FlexTableRow> initialData = const [],
  super.key,
  final ValueChanged<int>? onRowSelected,
  final bool pushDividers = true,
  final bool resizable = true,
  final ScrollController? scrollController,
  final List<int> selectedRows = const [],
  final bool shrinkWrap = false,
}) extends StatefulWidget {
  @override
  State createState() => _FlexTableState();
}

/// Defines the initial sizes for the columns within a [FlexTable].
class const FlexTableColumnSize({
  final double? flex,
  final double? maxFlex,
  final double? minFlex,
  final double? size,
}) {}

/// Controller to provide programmatic control over a [FlexTable].
class FlexTableController({
  FlexTableFilterer? filterFn,
  FlexTableSorter? sortFn,
}) {
  this
    : _filterFn =
          filterFn ?? ((String filter, String value) => filter != value),
      _sortFn = sortFn ?? _defaultSorter;

  final _columnController = StreamController<List<Area>>.broadcast();

  final FlexTableFilterer _filterFn;
  final _rowController = StreamController<void>.broadcast();

  final FlexTableSorter _sortFn;
  List<FlexTableRow> _allRows = [];

  List<Area> _areas = [];
  var _ascending = false;
  int? _filterIndex;
  String? _filterValue;
  List<FlexTableRow> _rows = [];
  int? _sortIndex;

  // ignore: ilt_lints/prefer_named_parameters
  static int _defaultSorter(bool ascending, String a, String b) {
    final aValue = a.toLowerCase();
    final bValue = b.toLowerCase();

    return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
  }

  /// Returns all the rows known by the [FlexTable].  This will ignore any
  /// current filter or sort and will maintain it's order based on the order the
  /// values were inserted.  The returned list will be unmodifiable.
  List<FlexTableRow> get allRows => List.unmodifiable(_allRows);

  /// Returns the current size values for all columns.
  List<FlexTableColumnSize> get columnSizes {
    final sizes = <FlexTableColumnSize>[];
    for (final area in _areas) {
      sizes.add(
        FlexTableColumnSize(
          flex: area.flex,
          maxFlex: area.max,
          minFlex: area.min,
          size: area.size,
        ),
      );
    }

    return sizes;
  }

  /// The event [Stream] that can be listened to for column events.  Whenever a
  /// modification is performed on a column, an event will be fired.
  Stream<void> get columnStream => _columnController.stream;

  /// The event [Stream] that can be listened to for row events.  Whenever a
  /// modification is performed on any row, an event will be fired.
  Stream<void> get rowStream => _rowController.stream;

  /// Contains all the rows that match any current filter and sorted in the
  /// defined sort order.  The returned list will be unmodifiable.
  List<FlexTableRow> get rows => _rows;

  /// Adds a [row] to the bottom / end of the [FlexTable].  This will fire an
  /// event that can be listened for on the [rowStream].
  ///
  /// When adding multiple rows, it is strongly suggested to use the [addRows]
  /// function instead as this will fire an event for each row, which can
  /// trigger a lot of sorting and filter processing where as [addRows] will
  /// only trigger a single event once all the rows have been added.
  void addRow(FlexTableRow row) {
    _allRows.add(row);
    _sortAndFilter();
  }

  /// Adds one or more [rows] to the bottom / end of the [FlexTable].  This will
  /// fire a single event to the [rowStream] after all the rows have been added.
  void addRows(Iterable<FlexTableRow> rows) {
    _allRows.addAll(rows);
    _sortAndFilter();
  }

  /// Disposes the controller and frees up its resources.
  void dispose() {
    _columnController.close();
    _rowController.close();
    _allRows = const [];
    _areas = const [];
    _rows = const [];
  }

  /// Sets the current filter and applies it to the [FlexTable].  If either the
  /// [index] or [value] is set to null, this will disable the sorting.
  void filter(int? index, String? value) {
    _filterIndex = index;
    _filterValue = value;

    _sortAndFilter();
  }

  /// Inserts a single [row] to the [FlexTable] at the [index].  The [index] is
  /// based on the [allRows].
  void insertRow(int index, FlexTableRow row) {
    _allRows.insert(index, row);
    _sortAndFilter();
  }

  /// Remove the [row] from the [FlexTable].  This will post an event to the
  /// [rowStream] if the row is removed.
  ///
  /// If multiple rows are being removed, use [removeRows] instead as that will
  /// only fire a single event once all rows have been removed.
  void removeRow(FlexTableRow row) {
    final removed = _allRows.remove(row);

    if (removed) {
      _sortAndFilter();
    }
  }

  /// Removes a row at the given [index].  The index is based on the [allRows]
  /// list and not the [rows] list.  This will post an event to the [rowStream]
  /// when the row is removed;
  void removeRowAt(int index) {
    _allRows.removeAt(index);
    _sortAndFilter();
  }

  /// Removes the given [rows] from the [FlexTable].
  ///
  /// This will post a single event at the end to the [rowStream] if at least
  /// one of the given [rows] was removed.
  void removeRows(Iterable<FlexTableRow> rows) {
    var removed = false;
    for (final row in rows) {
      removed = _allRows.remove(row) || removed;
    }

    if (removed) {
      _sortAndFilter();
    }
  }

  /// Removes all the existing data from the table and replaces it with the
  /// given [rows].
  void setRows(Iterable<FlexTableRow> rows) {
    _allRows.clear();
    _allRows.addAll(rows);
    _sortAndFilter();
  }

  /// Sets the current sort and applies it to the [FlexTable].  If the [index]
  /// is null, this will disable the sorting.
  void sort(int? index, bool ascending) {
    _ascending = ascending;
    _sortIndex = index;
    _sortAndFilter();
  }

  void _setColumns(List<Area> areas) {
    _areas = areas;
    _columnController.add(areas);
  }

  void _sortAndFilter() {
    final filterIndex = _filterIndex;
    final sortIndex = _sortIndex;
    final filtered = List<FlexTableRow>.from(_allRows);

    final filterValue = _filterValue;
    if (filterIndex != null && filterValue != null) {
      filtered.removeWhere(
        (row) => _filterFn(filterValue, row.columns[filterIndex].value),
      );
    }

    if (sortIndex != null) {
      filtered.sort(
        (a, b) => _sortFn(
          _ascending,
          a.columns[sortIndex].value.toLowerCase(),
          b.columns[sortIndex].value.toLowerCase(),
        ),
      );
    }

    _rows = List.unmodifiable(filtered);
    _rowController.add(null);
  }
}

class const _FlexFilterHeaderCell({
  required final Alignment alignment,
  required final FlexFilterController controller,
  required final Icon icon,
  required final int index,
  required final Widget child,
}) extends StatefulWidget {
  @override
  State createState() => _FlexFilterHeaderCellState();
}

class _FlexFilterHeaderCellState() extends State<_FlexFilterHeaderCell> {
  final List<StreamSubscription> subscriptions = [];

  @override
  void initState() {
    super.initState();

    subscriptions.add(widget.controller.stream.listen((_) => setState(() {})));
  }

  @override
  void dispose() {
    for (final sub in subscriptions) {
      sub.cancel();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filterIndex = widget.controller._filterIndex;
    final filterValue = widget.controller._filterValue;
    final indicator = filterIndex == widget.index ? widget.icon : null;

    final mq = MediaQuery.of(context);
    final theme = Theme.of(context);
    final monospace = TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: const <String>['Courier'],
      fontSize:
          (theme.listTileTheme.titleTextStyle ?? theme.textTheme.bodyLarge)
              ?.fontSize ??
          14.0,
    );

    return InkWell(
      onTap: () {
        // These lists can be very large and can include hundreds or even
        // thousands of values.  The built in menu button lags horrifically at
        // lists of this size because it needs to measure every row to determine
        // the width, and measuring text is relatively expensive.
        //
        // So... we cheat!  By using a monospaced font we only need to measure
        // a single longest word to determine the max width to use for the
        // whole popup regardless of the letters involved.
        //
        // This performs equally well when there are a handful of values to when
        // there are several thousand.
        var longestWord = '';
        var maxWidth = 80.0;

        final values = <String>{
          ...widget.controller.controller._allRows.map((row) {
            final value = row.columns[widget.index].value;
            if (longestWord.length < value.length) {
              longestWord = value;
            }

            return value;
          }),
        }.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

        final span = TextSpan(style: monospace, text: longestWord);
        final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
        tp.layout();

        maxWidth = max(maxWidth, tp.width);

        showPopover(
          bodyBuilder: (context) => SizedBox(
            height: min(mq.size.height - 120.0, values.length * 40.0 + 80.0),
            width: min(maxWidth + 100.0, mq.size.width - 100.0),
            child: Column(
              children: [
                ListTile(
                  onTap: () {
                    widget.controller.update(null, null);
                    Navigator.of(context).pop();
                  },
                  title: const Text('(clear)'),
                  trailing: const Icon(Icons.clear, color: Colors.red),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: values.length,
                    itemBuilder: (context, index) => ListTile(
                      onTap: () {
                        widget.controller.update(widget.index, values[index]);
                        Navigator.of(context).pop();
                      },
                      title: Text(values[index], style: monospace),
                      trailing: values[index] == filterValue
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          context: context,
          direction: PopoverDirection.top,
        );
      },
      child: indicator == null
          ? widget.child
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                if (widget.alignment.x < 0.0)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: indicator,
                  ),
                if (widget.alignment.x == 0.0) ...[
                  widget.child,
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: indicator,
                  ),
                ],
                if (widget.alignment.x != 0.0) Expanded(child: widget.child),
                if (widget.alignment.x > 0.0)
                  Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: indicator,
                  ),
              ],
            ),
    );
  }
}

class const _FlexSortHeaderCell({
  required final Alignment alignment,
  required final Icon ascendingIcon,
  required final FlexSortController controller,
  required final Icon descendingIcon,
  required final int index,
  required final Widget child,
}) extends StatefulWidget {
  @override
  State createState() => _FlexSortHeaderCellState();
}

class _FlexSortHeaderCellState() extends State<_FlexSortHeaderCell> {
  final List<StreamSubscription> subscriptions = [];

  @override
  void initState() {
    super.initState();

    subscriptions.add(widget.controller.stream.listen((_) => setState(() {})));
  }

  @override
  void dispose() {
    for (final sub in subscriptions) {
      sub.cancel();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortIndex = widget.controller._columnIndex;
    final ascending = widget.controller.ascending;
    final indicator = sortIndex == widget.index
        ? Builder(
            key: ValueKey(ascending ? 'ascending' : 'descending'),
            builder: (context) =>
                ascending ? widget.ascendingIcon : widget.descendingIcon,
          )
        : null;

    return InkWell(
      onTap: () {
        widget.controller.update(
          widget.index,
          sortIndex != widget.index ? true : !widget.controller._ascending,
        );
      },
      child: indicator == null
          ? widget.child
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                if (widget.alignment.x < 0.0)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: indicator,
                  ),
                if (widget.alignment.x == 0.0) ...[
                  widget.child,
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: indicator,
                  ),
                ],
                if (widget.alignment.x != 0.0) Expanded(child: widget.child),
                if (widget.alignment.x > 0.0)
                  Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: indicator,
                  ),
              ],
            ),
    );
  }
}

class const _FlexTableHeader({
  required final List<FlexTableCell> columns,
  required final FlexTableController controller,
  required final FlexHeaderDividerBuilder dividerBuilder,
  required final List<FlexTableColumnSize>? initialColumnSizes,
  required final bool pushDividers,
  required final bool resizable,
  required final TextStyle? style,
  required final FlexCellBuilder builder,
}) extends StatefulWidget {
  @override
  State createState() => _FlexTableHeaderState();
}

class _FlexTableHeaderState() extends State<_FlexTableHeader> {
  final multiSplitViewController = MultiSplitViewController();
  final List<StreamSubscription> subscriptions = [];

  @override
  void initState() {
    super.initState();

    for (var i = 0; i < widget.columns.length; i++) {
      final size = widget
          .initialColumnSizes?[min(i, widget.initialColumnSizes?.length ?? 0)];
      final column = widget.columns[i];
      multiSplitViewController.addArea(
        Area(
          builder: (context, area) => widget.builder.build(
            child: column,
            columnIndex: i,
            context: context,
            rowIndex: -1,
            selected: false,
          ),
          flex: size?.flex,
          max: size?.maxFlex,
          min: size?.minFlex,
          size: size?.size,
        ),
      );
    }
    widget.controller._setColumns(multiSplitViewController.areas);
    multiSplitViewController.addListener(multiSplitViewControllerListener);
  }

  @override
  void dispose() {
    multiSplitViewController.removeListener(multiSplitViewControllerListener);
    multiSplitViewController.dispose();
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
    subscriptions.clear();

    super.dispose();
  }

  void multiSplitViewControllerListener() =>
      widget.controller._setColumns(multiSplitViewController.areas);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2.0,
      child: MultiSplitView(
        controller: multiSplitViewController,
        dividerBuilder: widget.resizable
            ? (axis, index, resizable, dragging, highlighted, themeData) =>
                  widget.dividerBuilder.build(
                    axis: axis,
                    context: context,
                    dragging: dragging,
                    highlighted: highlighted,
                    index: index,
                    resizable: resizable,
                    themeData: themeData,
                  )
            : (axis, index, resizable, dragging, highlighted, themeData) =>
                  widget.builder.build(
                    child: const SizedBox(),
                    columnIndex: index,
                    context: context,
                    rowIndex: -1,
                    selected: false,
                  ),
        pushDividers: widget.pushDividers,
        resizable: widget.resizable,
      ),
    );
  }
}

class _FlexTableRow({
  required final FlexTableController controller,
  required final FlexTableRow data,
  required final int index,
  required final bool selected,
  required final TextStyle? style,
  required final FlexCellBuilder builder,
}) extends StatefulWidget {
  this : super(key: ValueKey(data.key));

  @override
  State createState() => _FlexTableRowState();
}

class _FlexTableRowState() extends State<_FlexTableRow> {
  final controller = MultiSplitViewController();
  final List<StreamSubscription> subscriptions = [];

  @override
  void initState() {
    super.initState();

    for (var i = 0; i < widget.data.columns.length; i++) {
      final headerArea = widget.controller._areas[i];
      controller.addArea(buildArea(headerArea, i));
    }
    final columns = widget.data.columns;
    subscriptions.add(
      widget.controller._columnController.stream.listen((areas) {
        final newAreas = <Area>[];
        final style = widget.style;
        for (var i = 0; i < columns.length; i++) {
          final area = areas[i];
          final id = controller.getArea(i).id;
          newAreas.add(
            Area(
              builder: (context, area) => widget.builder.build(
                child: style == null
                    ? columns[i]
                    : DefaultTextStyle(style: style, child: columns[i]),
                columnIndex: i,
                context: context,
                rowIndex: widget.index,
                selected: widget.selected,
              ),
              flex: area.flex,
              id: id,
              max: area.max,
              min: area.min,
              size: area.size,
            ),
          );
        }
        controller.areas = newAreas;
      }),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
    subscriptions.clear();

    super.dispose();
  }

  Area buildArea(Area header, int index) {
    final style = widget.style;
    return Area(
      builder: (context, area) => widget.builder.build(
        child: style == null
            ? widget.data.columns[index]
            : DefaultTextStyle(style: style, child: widget.data.columns[index]),
        columnIndex: index,
        context: context,
        rowIndex: widget.index,
        selected: widget.selected,
      ),
      flex: header.flex,
      max: header.max,
      min: header.min,
      size: header.size,
    );
  }

  @override
  Widget build(BuildContext context) => MultiSplitView(
    controller: controller,
    dividerBuilder:
        (axis, index, resizable, dragging, highlighted, themeData) =>
            widget.builder.build(
              child: const SizedBox(),
              columnIndex: index,
              context: context,
              rowIndex: widget.index,
              selected: widget.selected,
            ),
    resizable: false,
  );
}

class _FlexTableState() extends State<FlexTable> {
  final List<StreamSubscription> subscriptions = [];

  @override
  void initState() {
    super.initState();

    widget.controller.addRows(widget.initialData);
  }

  @override
  void dispose() {
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
    subscriptions.clear();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emptyDataBuilder = widget.controller._rows.isNotEmpty
        ? null
        : widget.emptyDataBuilder;
    final onRowSelected = widget.onRowSelected;
    return MultiProvider(
      providers: [
        Provider.value(value: widget.controller),
        Provider.value(value: widget.dataBuilder),
        Provider.value(value: widget.headerBuilder),
        Provider.value(value: widget.headerDividerBuilder),
      ],
      child: Column(
        children: [
          SizedBox(
            height: widget.headerHeight,
            child: _FlexTableHeader(
              columns: widget.headers,
              controller: widget.controller,
              dividerBuilder: widget.headerDividerBuilder,
              initialColumnSizes: widget.initialColumnSizes,
              pushDividers: widget.pushDividers,
              resizable: widget.resizable,
              style: widget.headerStyle,
              builder: widget.headerBuilder,
            ),
          ),
          Divider(height: 0.0),
          Expanded(
            child: StreamBuilder(
              stream: widget.controller._rowController.stream,
              builder: (context, snapshot) => emptyDataBuilder != null
                  ? emptyDataBuilder(context)
                  : ListView.builder(
                      controller: widget.scrollController,
                      itemCount: widget.controller._rows.length,
                      shrinkWrap: widget.shrinkWrap,
                      itemBuilder: (context, index) => SizedBox(
                        height: widget.dataHeight,
                        child: Material(
                          child: InkWell(
                            onTap: onRowSelected == null
                                ? null
                                : () => onRowSelected(index),
                            child: _FlexTableRow(
                              controller: widget.controller,
                              data: widget.controller._rows[index],
                              index: index,
                              selected: widget.selectedRows.contains(index),
                              style: widget.dataStyle,
                              builder: widget.dataBuilder,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
