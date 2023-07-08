import 'package:flutter/material.dart';

class ArgCheckbox extends StatelessWidget {
  const ArgCheckbox({
    super.key,
    required this.value,
    required this.text,
    required this.onChanged,
  });

  final bool value;
  final String text;
  final void Function(bool?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
        ),
        Text(text),
      ],
    );
  }
}
