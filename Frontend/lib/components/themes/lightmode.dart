import 'package:flutter/material.dart';
import 'package:vetconnect/components/coloors/colors.dart';
import 'package:vetconnect/components/extension/custom_theme.dart';

ThemeData lightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    primaryColor: CustomColors.appblue,
    scaffoldBackgroundColor: Colors.white,
    extensions: const [CustomThemeExtension.lightMode],
  );
}
