import 'package:churchdata_core/churchdata_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class CDThemingService extends ThemingService {
  static ThemeData getDefault({
    bool? darkTheme,
    bool? greatFeastThemeOverride,
  }) {
    bool isDark = darkTheme ??
        GetIt.I<CacheRepository>().box('Settings').get('DarkTheme') ??
        PlatformDispatcher.instance.platformBrightness == Brightness.dark;

    final bool greatFeastTheme = GetIt.I<CacheRepository>()
        .box('Settings')
        .get('GreatFeastTheme', defaultValue: greatFeastThemeOverride ?? true);

    MaterialColor primary = Colors.cyan;
    Color secondary = Colors.cyanAccent;

    final riseDay = getRiseDay();
    if (greatFeastTheme &&
        DateTime.now()
            .isAfter(riseDay.subtract(const Duration(days: 7, seconds: 20))) &&
        DateTime.now().isBefore(riseDay.subtract(const Duration(days: 1)))) {
      primary = ThemingService.black;
      secondary = ThemingService.blackAccent;
      isDark = true;
    } else if (greatFeastTheme &&
        DateTime.now()
            .isBefore(riseDay.add(const Duration(days: 50, seconds: 20))) &&
        DateTime.now().isAfter(riseDay.subtract(const Duration(days: 1)))) {
      isDark = false;
    }

    return ThemeData.from(
      colorScheme: ColorScheme.fromSwatch(
        backgroundColor: isDark ? Colors.grey[850]! : Colors.grey[50]!,
        brightness: isDark ? Brightness.dark : Brightness.light,
        primarySwatch: primary,
        accentColor: secondary,
      ),
    ).copyWith(
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: primary),
        ),
      ),
      floatingActionButtonTheme:
          const FloatingActionButtonThemeData(shape: CircleBorder()),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      brightness: isDark ? Brightness.dark : Brightness.light,
      // textButtonTheme: TextButtonThemeData(
      //   style: TextButton.styleFrom(
      //     shape: RoundedRectangleBorder(
      //       borderRadius: BorderRadius.circular(15),
      //     ),
      //   ),
      // ),
      // outlinedButtonTheme: OutlinedButtonThemeData(
      //   style: OutlinedButton.styleFrom(
      //     shape: RoundedRectangleBorder(
      //       borderRadius: BorderRadius.circular(15),
      //     ),
      //   ),
      // ),
      // elevatedButtonTheme: ElevatedButtonThemeData(
      //   style: ElevatedButton.styleFrom(
      //     shape: RoundedRectangleBorder(
      //       borderRadius: BorderRadius.circular(15),
      //     ),
      //   ),
      // ),
      // appBarTheme: AppBarTheme(
      //   backgroundColor: primary,
      //   foregroundColor: (isDark
      //           ? Typography.material2018().white
      //           : Typography.material2018().black)
      //       .titleLarge
      //       ?.color,
      //   systemOverlayStyle:
      //       isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      // ),
      bottomAppBarTheme: BottomAppBarTheme(
        color: secondary,
        shape: const CircularNotchedRectangle(),
      ),
    );
  }

  factory CDThemingService() =>
      CDThemingService.withInitialThemeata(getDefault());

  CDThemingService.withInitialThemeata(super.initialTheme)
      : super.withInitialThemeata();

  @override
  void switchTheme(bool darkTheme) {
    theme = getDefault(darkTheme: darkTheme);
  }
}
