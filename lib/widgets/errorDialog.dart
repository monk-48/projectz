import 'package:flutter/material.dart';

class Errordialog extends StatelessWidget {
  final String message;
  Errordialog({required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: key,
      content: Text(message!),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Center(
            child: Text(
              "OK",
              style: TextStyle(color: Colors.white),
            ),
          ),
        )
      ],
    );
  }
}