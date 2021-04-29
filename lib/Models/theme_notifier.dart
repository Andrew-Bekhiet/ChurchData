import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class ThemeNotifier {
  final BehaviorSubject<ThemeData> _themeData;

  ThemeNotifier(ThemeData themeData)
      : _themeData = BehaviorSubject.seeded(themeData);

  ThemeData get theme => _themeData.value;

  Stream<ThemeData> get stream => _themeData.stream;

  set theme(ThemeData themeData) {
    _themeData.add(themeData);
  }

  Future<void> dispose() async {
    await _themeData.close();
  }
}
