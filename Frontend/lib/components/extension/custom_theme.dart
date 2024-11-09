import 'package:flutter/material.dart';
import 'package:vetconnect/components/coloors/colors.dart';

extension ExtendedTheme on BuildContext {
  CustomThemeExtension get theme {
    final customTheme = Theme.of(this).extension<CustomThemeExtension>();
    return customTheme ?? CustomThemeExtension.lightMode;
  }
}

class CustomThemeExtension extends ThemeExtension<CustomThemeExtension> {
  final Color? curvedpartcolor;
  final Color? titletext;
  final subtitletext;
  final primecolor;
  final Color? deepprimecolor;

  const CustomThemeExtension({
    required this.curvedpartcolor,
    required this.titletext,
    required this.subtitletext,
    required this.primecolor,
    required this.deepprimecolor,
  });

  static const lightMode = CustomThemeExtension(
    curvedpartcolor: Colors.white,
    titletext: Colors.black,
    subtitletext: Colors.grey,
    primecolor: CustomColors.appblue,
    deepprimecolor: CustomColors.dimblue,
  );

  static const darkMode = CustomThemeExtension(
    curvedpartcolor: Color.fromARGB(255, 18, 18, 18),
    titletext: Colors.white,
    subtitletext: Color.fromARGB(255, 163, 162, 162),
    primecolor: Color.fromARGB(255, 0, 117, 138),
    deepprimecolor: Color.fromARGB(255, 4, 85, 99),
  );

  @override
  CustomThemeExtension copyWith({Color? curvedpartcolor}) {
    return CustomThemeExtension(
      curvedpartcolor: curvedpartcolor ?? this.curvedpartcolor,
      titletext: titletext ?? titletext,
      subtitletext: subtitletext ?? subtitletext,
      primecolor: primecolor ?? primecolor,
      deepprimecolor: deepprimecolor ?? deepprimecolor,
    );
  }

  @override
  CustomThemeExtension lerp(
      ThemeExtension<CustomThemeExtension>? other, double t) {
    if (other is! CustomThemeExtension) return this;
    return CustomThemeExtension(
      curvedpartcolor: Color.lerp(curvedpartcolor, other.curvedpartcolor, t)!,
      titletext: Color.lerp(titletext, other.titletext, t)!,
      subtitletext: Color.lerp(subtitletext, other.subtitletext, t)!,
      primecolor: Color.lerp(primecolor, other.primecolor, t)!,
      deepprimecolor: Color.lerp(deepprimecolor, other.deepprimecolor, t)!,
    );
  }
}
