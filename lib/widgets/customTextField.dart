import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  
  final TextEditingController? controller;
  final IconData? data;
  final String? hintText;
  final bool isObsecure; 
  final bool enabled;

  CustomTextField({
    this.controller,
    this.data,
    this.hintText,
    this.isObsecure = true,
    this.enabled = true,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        padding: const EdgeInsets.all(8.0) ,
        margin: const EdgeInsets.all( 10.0),
        child: TextFormField(
          enabled: enabled,
          controller: controller,
          obscureText: isObsecure,
          cursorColor: Theme.of(context).primaryColor,
          decoration: InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(
                data,
                color: Colors.cyan,
            ),
            focusColor: Theme.of(context).primaryColor,
            hintText: hintText,
          ),
        )
    );
  }
}