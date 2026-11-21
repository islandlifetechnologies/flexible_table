import 'dart:async';
import 'dart:math';

import 'package:english_words/english_words.dart';
import 'package:flexible_table/flexible_table.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

class const MixedWidgetsFlexTable({super.key}) extends StatefulWidget {
  @override
  State createState() => _MixedWidgetsFlexTable();
}

class _MixedWidgetsFlexTable() extends State<MixedWidgetsFlexTable> {
  static const kColumns = 6;

  final controller = FlexTableController();
  final List<FlexTableCell> headers = [
    FlexTableCell(
      value: 'false',
      child: Checkbox(onChanged: (_) {}, value: false),
    ),
    for (var i = 1; i < kColumns; i++) FlexTableCell(value: 'Random #$i'),
  ];

  late final sortController = FlexSortController(controller: controller);

  late final Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final columns = <FlexTableCell>[];
      final random = Random();

      columns.add(
        const FlexTableCell(value: 'false', child: StatefulCheckbox()),
      );

      for (var i = 1; i < kColumns; i++) {
        final word = nouns[random.nextInt(nouns.length)];
        columns.add(FlexTableCell(value: word));
      }

      controller.addRow(FlexTableRow(columns: columns));
    });
  }

  @override
  void dispose() {
    controller.dispose();
    sortController.dispose();
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          StreamBuilder(
            stream: controller.rowStream,
            builder: (context, _) => Padding(
              padding: kDebugMode
                  ? const EdgeInsets.only(right: 48.0)
                  : const EdgeInsets.only(right: 16.0),
              child: Text(controller.allRows.length.toString()),
            ),
          ),
        ],
        title: const Text('Mixed Widgets'),
      ),
      body: FlexTable(
        controller: controller,
        dataBuilder: const FlexStripeCellBuilder(),
        headerBuilder: FlexSortHeaderCellBuilder(controller: sortController),
        headers: headers,
      ),
    );
  }
}

class const StatefulCheckbox({super.key}) extends StatefulWidget {
  @override
  State createState() => _StatefulCheckboxState();
}

class _StatefulCheckboxState() extends State<StatefulCheckbox> {
  var _selected = false;

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      onChanged: (checked) => setState(() => _selected = checked == true),
      value: _selected,
    );
  }
}
