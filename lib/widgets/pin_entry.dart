import 'package:flutter/material.dart';

class PinEntry extends StatefulWidget {
  final String correctPin;
  final Function(String) onPinEntered;

  const PinEntry({
    super.key,
    required this.correctPin,
    required this.onPinEntered,
  });

  @override
  State<PinEntry> createState() => _PinEntryState();
}

class _PinEntryState extends State<PinEntry> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      obscureText: true,
      maxLength: 4,
      decoration: const InputDecoration(
        hintText: 'Enter 4-digit PIN',
        counterText: '',
      ),
      onChanged: (value) {
        if (value.length == 4) {
          if (value == widget.correctPin) {
            widget.onPinEntered(value);
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Incorrect PIN')));
            _controller.clear();
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
