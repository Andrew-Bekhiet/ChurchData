import 'package:churchdata_core/churchdata_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class CDThemingService extends ThemingService {
  static ThemeData getDefault({
    Color? seedOverride,
    bool? isDarkOverride,
    bool? greatFeastThemeOverride,
  }) {
    bool isDark = isDarkOverride ??
        GetIt.I<CacheRepository>().box('Settings').get('DarkTheme') ??
        PlatformDispatcher.instance.platformBrightness == Brightness.dark;

    final bool greatFeastTheme = greatFeastThemeOverride ??
        GetIt.I<CacheRepository>().box('Settings').get(
              'GreatFeastTheme',
              defaultValue: greatFeastThemeOverride ?? true,
            );

    Color seed = seedOverride ?? Colors.cyan;
    final riseDay = getRiseDay();
    if (greatFeastTheme &&
        DateTime.now()
            .isAfter(riseDay.subtract(const Duration(days: 7, seconds: 20))) &&
        DateTime.now().isBefore(riseDay.subtract(const Duration(days: 1)))) {
      seed = ThemingService.black;
      isDark = true;
    } else if (greatFeastTheme &&
        DateTime.now()
            .isBefore(riseDay.add(const Duration(days: 50, seconds: 20))) &&
        DateTime.now().isAfter(riseDay.subtract(const Duration(days: 1)))) {
      isDark = false;
    }

    final ColorScheme colorScheme = ColorScheme.fromSwatch(
      backgroundColor: isDark ? Colors.grey[850]! : Colors.grey[50]!,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primarySwatch: Colors.cyan,
      accentColor: Colors.cyanAccent,
    );

    final Typography typography = Typography.material2021(
      platform: defaultTargetPlatform,
      colorScheme: colorScheme,
    );

    final themeData = ThemeData.from(
      textTheme: isDark ? typography.white : typography.black,
      colorScheme: colorScheme,
      useMaterial3: true,
    );

    return themeData.copyWith(
      cardTheme: themeData.cardTheme.copyWith(
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(15)),
          borderSide: BorderSide(color: seed),
        ),
      ),
      floatingActionButtonTheme:
          const FloatingActionButtonThemeData(shape: CircleBorder()),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      brightness: isDark ? Brightness.dark : Brightness.light,
      bottomAppBarTheme: const BottomAppBarTheme(
        color: Colors.cyanAccent,
        shape: CircularNotchedRectangle(),
      ),
    );
  }

  factory CDThemingService() =>
      CDThemingService.withInitialThemeata(getDefault());

  CDThemingService.withInitialThemeata(super.initialTheme)
      : super.withInitialThemeata();

  @override
  void switchTheme(bool darkTheme) {
    theme = getDefault(isDarkOverride: darkTheme);
  }
}
