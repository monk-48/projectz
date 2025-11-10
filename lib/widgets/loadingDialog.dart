import 'package:flutter/material.dart';
import 'package:projectz/widgets/porgressBar.dart';

class LoadingDialog extends StatelessWidget {
  final String message;
  LoadingDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: key,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          circularProgress(),
          SizedBox(height: 10,),
          Text( message + "Autheniticating, Please wait..."),
        ],
      ),
        
    );
  }
}