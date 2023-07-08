import 'package:flutter/material.dart';

class ArgDropdown extends StatefulWidget {
  const ArgDropdown({
    super.key,
    required this.onChanged,
    required this.value,
    required this.opts,
  });

  final int value;
  final void Function(dynamic value) onChanged;
  final List<String> opts;

  @override
  State<ArgDropdown> createState() => _ArgDropdownState();
}

class _ArgDropdownState extends State<ArgDropdown> {
  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      items: [
        for (int i = 0; i < widget.opts.length; ++i)
          DropdownMenuItem<int>(value: i, child: Text(widget.opts[i])),
      ],
      onChanged: widget.onChanged,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      value: widget.value,
    );
  }
}
