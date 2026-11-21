import 'dart:async';
import 'dart:math';

import 'package:english_words/english_words.dart';
import 'package:flexible_table/flexible_table.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

class const InitialFlexTableSizes({
  super.key,
  final bool sortable = false,
  final bool striped = false,
  required final String title,
}) extends StatefulWidget {
  @override
  State createState() => _InitialFlexTableSizesState();
}

class _InitialFlexTableSizesState() extends State<InitialFlexTableSizes> {
  final _controller = FlexTableController();
  final _headers = <FlexTableCell>[
    const FlexTableCell(value: 'Small'),
    const FlexTableCell(value: 'Medium'),
    const FlexTableCell(value: 'Large'),
    const FlexTableCell(value: 'Has Minimum'),
    const FlexTableCell(value: 'Has Maximum'),
    const FlexTableCell(value: 'Sized'),
  ];

  final _sizes = <FlexTableColumnSize>[
    FlexTableColumnSize(flex: 0.5),
    FlexTableColumnSize(flex: 1.0),
    FlexTableColumnSize(flex: 2.0),
    FlexTableColumnSize(minFlex: 1.0),
    FlexTableColumnSize(maxFlex: 2.0),
    FlexTableColumnSize(size: 200.0),
  ];
  late final _sortController = FlexSortController(controller: _controller);

  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final columns = <FlexTableCell>[];
      final random = Random();

      for (var i = 0; i < _headers.length; i++) {
        final word = nouns[random.nextInt(nouns.length)];
        columns.add(FlexTableCell(value: word));
      }

      _controller.addRow(FlexTableRow(columns: columns));

      if (_controller.rows.length > 1000) {
        _timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _sortController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          StreamBuilder(
            stream: _controller.rowStream,
            builder: (context, _) => Padding(
              padding: kDebugMode
                  ? const EdgeInsets.only(right: 48.0)
                  : const EdgeInsets.only(right: 16.0),
              child: Text(_controller.allRows.length.toString()),
            ),
          ),
        ],
        title: Text(widget.title),
      ),
      body: FlexTable(
        controller: _controller,
        dataBuilder: widget.striped
            ? const FlexStripeCellBuilder()
            : const FlexDataCellBuilder(),
        headerBuilder: widget.sortable
            ? FlexSortHeaderCellBuilder(controller: _sortController)
            : const FlexHeaderCellBuilder(),
        headers: _headers,
        initialColumnSizes: _sizes,
      ),
    );
  }
}
