import 'package:flutter/material.dart';
import 'package:projectz/widgets/customTextField.dart';

class loginScreen extends StatefulWidget {
  const loginScreen({Key? key}) : super(key: key);

  @override
  State<loginScreen> createState() => _loginScreenState();
}

class _loginScreenState extends State<loginScreen> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController emailFieldController = TextEditingController();
  TextEditingController passwordFieldController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Image.asset(
                  'images/seller.png',
                  height: 270,
                ),
              ),
            ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  CustomTextField(
                    controller: emailFieldController,
                    data: Icons.email,
                    hintText: 'Email',
                    isObsecure: false,
                  ),
                  CustomTextField(
                    controller: passwordFieldController,
                    data: Icons.lock,
                    hintText: 'Password',
                  ),
                ],
              ),
            ),
            ElevatedButton(
              child: const Text(
                "LogIn",
                style: TextStyle(
                  color: Color.fromARGB(255, 162, 148, 196),
                  fontSize: 18,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              ),
              onPressed: () => print("Clicked"),
              ),
            const SizedBox( height: 30, ),
          ],
        ),
    );
  }
}