import 'dart:async';
import 'dart:math';

import 'package:english_words/english_words.dart';
import 'package:flexible_table/flexible_table.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

class const DynamicFlexTable({
  super.key,
  final bool sortable = false,
  final bool striped = false,
  required final String title,
}) extends StatefulWidget {
  @override
  State createState() => _DynamicFlexTableState();
}

class _DynamicFlexTableState() extends State<DynamicFlexTable> {
  static const kColumns = 6;

  final _controller = FlexTableController();
  final List<FlexTableCell> _headers = [
    for (var i = 1; i <= kColumns; i++) FlexTableCell(value: 'Random #$i'),
  ];

  late final _sortController = FlexSortController(controller: _controller);

  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final columns = <FlexTableCell>[];
      final random = Random();

      for (var i = 0; i < kColumns; i++) {
        final word = nouns[random.nextInt(nouns.length)];
        columns.add(FlexTableCell(value: word));
      }

      _controller.addRow(FlexTableRow(columns: columns));
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
        onRowSelected: (index) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Row Selected: $index')));
        },
      ),
    );
  }
}
