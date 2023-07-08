import 'package:flutter/material.dart';

class ArgDropdown extends StatefulWidget {
  const ArgDropdown({
    super.key,
    required this.onChanged,
    required this.value,
    required this.opts,
  });

  final String value;
  final void Function(dynamic value) onChanged;
  final Map<String, String> opts;

  @override
  State<ArgDropdown> createState() => _ArgDropdownState();
}

class _ArgDropdownState extends State<ArgDropdown> {
  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      items: [
        for (String i in widget.opts.keys)
          DropdownMenuItem<String>(value: widget.opts[i], child: Text(i)),
      ],
      onChanged: widget.onChanged,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      value: widget.value,
    );
  }
}
