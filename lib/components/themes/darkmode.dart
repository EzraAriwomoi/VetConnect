import 'package:flutter/material.dart';
import 'package:vetconnect/components/coloors/colors.dart';
import 'package:vetconnect/components/extension/custom_theme.dart';

ThemeData darkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    primaryColor: CustomColors.appblue,
    scaffoldBackgroundColor: Color.fromARGB(255, 18, 18, 18),
    extensions: const [CustomThemeExtension.darkMode],
  );
}
