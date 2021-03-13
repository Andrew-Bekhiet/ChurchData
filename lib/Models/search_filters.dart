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
  const SearchField({Key key, @required this.textStyle}) : super(key: key);
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: textStyle,
      decoration: InputDecoration(
          suffixIcon: IconButton(
            icon: Icon(Icons.close, color: textStyle.color),
            onPressed: () => context.read<SearchString>().value = '',
          ),
          hintStyle: textStyle,
          icon: Icon(Icons.search, color: textStyle.color),
          hintText: 'بحث ...'),
      onChanged: (t) => context.read<SearchString>().value = t,
    );
  }
}

class SearchFilters extends StatelessWidget {
  final int index;
  final TextStyle textStyle;
  const SearchFilters(this.index, {Key key, @required this.textStyle})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SearchField(
            textStyle: textStyle ??
                Theme.of(context).textTheme.headline6.copyWith(
                    color: Theme.of(context).primaryTextTheme.headline6.color),
          ),
        ),
        FilterButton(index)
      ],
    );
  }
}
