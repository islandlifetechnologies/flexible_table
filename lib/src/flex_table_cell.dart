import 'package:flexible_table/src/flex_table.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class const FlexTableCell({
  super.key,
  required final String value,
  final Widget? child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return child ??
        Text(
          value,
          maxLines: context.read<FlexDataCellBuilder>().maxLines,
          overflow: TextOverflow.ellipsis,
        );
  }
}
