import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../utils/helpers.dart';
import 'list_options.dart';
import 'order_options.dart';

class FilterButton extends StatelessWidget {
  final int index;
  final BaseListOptions controller;
  final BehaviorSubject<OrderOptions> orderOptions;
  final bool disableOrdering;
  const FilterButton(this.index, this.controller, this.orderOptions,
      {Key key, this.disableOrdering = false})
      : assert(orderOptions != null || disableOrdering),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.filter_list),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => SimpleDialog(
            children: [
              TextButton.icon(
                icon: Icon(Icons.select_all),
                label: Text('تحديد الكل'),
                onPressed: () {
                  controller.selectAll();
                  Navigator.pop(context);
                },
              ),
              TextButton.icon(
                icon: Icon(Icons.select_all),
                label: Text('تحديد لا شئ'),
                onPressed: () {
                  controller.selectNone();
                  Navigator.pop(context);
                },
              ),
              if (!disableOrdering)
                Text('ترتيب حسب:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              if (!disableOrdering)
                ...getOrderingOptions(context, orderOptions, index)
            ],
          ),
        );
      },
    );
  }
}

class SearchField extends StatelessWidget {
  SearchField({Key key, @required this.textStyle, @required this.searchStream})
      : super(key: key);
  final TextStyle textStyle;
  final TextEditingController _textController = TextEditingController();
  final BehaviorSubject<String> searchStream;

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: textStyle,
      controller: _textController,
      decoration: InputDecoration(
          suffixIcon: IconButton(
            icon: Icon(Icons.close, color: textStyle.color),
            onPressed: () {
              _textController.text = '';
              searchStream.add('');
            },
          ),
          hintStyle: textStyle,
          icon: Icon(Icons.search, color: textStyle.color),
          hintText: 'بحث ...'),
      onChanged: (_) => searchStream.add(_),
    );
  }
}

class SearchFilters extends StatelessWidget {
  final int index;
  final TextStyle textStyle;
  final BaseListOptions options;
  final BehaviorSubject<OrderOptions> orderOptions;
  final BehaviorSubject<String> searchStream;
  final bool disableOrdering;
  const SearchFilters(this.index,
      {Key key,
      @required this.textStyle,
      @required this.options,
      @required this.searchStream,
      this.disableOrdering = false,
      this.orderOptions})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SearchField(
            searchStream: searchStream,
            textStyle: textStyle ??
                Theme.of(context).textTheme.headline6.copyWith(
                    color: Theme.of(context).primaryTextTheme.headline6.color),
          ),
        ),
        FilterButton(
          index,
          options,
          orderOptions,
          disableOrdering: disableOrdering,
        ),
      ],
    );
  }
}
