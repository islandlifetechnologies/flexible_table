import 'package:flexible_table/flexible_table.dart';
import 'package:material_ui/material_ui.dart';

class const EmptyFlexTable({super.key, required final String title})
    extends StatefulWidget {
  @override
  State createState() => _EmptyFlexTableState();
}

class _EmptyFlexTableState() extends State<EmptyFlexTable> {
  static const kColumns = 6;

  final _controller = FlexTableController();

  final List<FlexTableCell> _headers = [
    for (var i = 1; i <= kColumns; i++) FlexTableCell(value: 'Empty #$i'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FlexTable(
        controller: _controller,
        emptyDataBuilder: (context) => const Center(
          child: SizedBox(
            height: 100.0,
            width: 100.0,
            child: Material(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
        ),
        headers: _headers,
      ),
    );
  }
}
