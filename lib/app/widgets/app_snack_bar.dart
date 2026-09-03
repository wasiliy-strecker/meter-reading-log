import 'package:flutter/material.dart';

class AppSnackBar extends SnackBar {
  AppSnackBar({super.key, required String message})
    : super(
        content: SizedBox(
          width: double.infinity,
          child: Text(message, textAlign: TextAlign.center),
        ),
      );
}
