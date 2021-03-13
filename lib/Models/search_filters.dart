import 'package:churchdata/models/order_options.dart';
import 'package:churchdata/models/search_string.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FilterButton extends StatelessWidget {
  final int index;
  const FilterButton(this.index, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.filter_list),
      onPressed: () {
        var orderOptions = context.read<OrderOptions>();
        showDialog(
          context: context,
          builder: (context) => SimpleDialog(
            children: [
              TextButton.icon(
                icon: Icon(Icons.select_all),
                label: Text('تحديد الكل'),
                onPressed: () {
                  orderOptions.personSelectAll.add(true);
                  Navigator.pop(context);
                },
              ),
              TextButton.icon(
                icon: Icon(Icons.select_all),
                label: Text('تحديد لا شئ'),
                onPressed: () {
                  orderOptions.personSelectAll.add(false);
                  Navigator.pop(context);
                },
              ),
              Text('ترتيب حسب:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...getOrderingOptions(context, orderOptions, index)
            ],
          ),
        );
      },
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration:
          InputDecoration(icon: Icon(Icons.search), hintText: 'بحث ...'),
      onChanged: (t) => context.read<SearchString>().value = t,
    );
  }
}

class SearchFilters extends StatelessWidget {
  final int index;
  const SearchFilters(this.index, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SearchField(),
        ),
        FilterButton(index)
      ],
    );
  }
}
