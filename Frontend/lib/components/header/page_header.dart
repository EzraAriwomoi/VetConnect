import 'package:flutter/material.dart';
import 'package:vetconnect/components/extension/custom_theme.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const PageHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Image.asset(
            'assets/logo.png',
            height: 150,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 28,
            color: context.theme.titletext,
          ),
        ),
        SizedBox(height: 10),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 17,
            color: context.theme.subtitletext,
          ),
        ),
      ],
    );
  }
}
