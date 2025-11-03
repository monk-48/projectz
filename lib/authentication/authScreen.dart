import 'package:flutter/material.dart';
import 'package:projectz/authentication/login.dart';
import 'package:projectz/authentication/register.dart';
class AuthScreen extends StatelessWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, 
      child: Scaffold (
        appBar: AppBar(
          flexibleSpace: Container(
            decoration:  const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pinkAccent, Colors.purpleAccent],
                begin: FractionalOffset(0.0, 0.0),
                end: FractionalOffset(1.0, 0.0),
                stops: [0.0, 1.0],
                tileMode: TileMode.clamp,
              ),
            ),
          ),
          automaticallyImplyLeading: false ,
        title: const Text(
          'Authentication',
          style: TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'lobster',
          ),
        ),
        centerTitle: true,
        bottom: const TabBar(
          tabs: [
            Tab(
              icon: Icon(Icons.lock, color: Colors.white,),
              text: 'Login',
            ),
            Tab(
              icon: Icon(Icons.person, color: Colors.white,),
              text: 'Register',
            ),
          ], 
          indicatorColor: Colors.white38,
          indicatorWeight: 5,
          ),
      ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pinkAccent, Colors.purpleAccent],
              begin: FractionalOffset(0.0, 0.0),
              end: FractionalOffset(1.0, 0.0),
              stops: [0.0, 1.0],
              tileMode: TileMode.clamp,
            ),
          ),
          child: const TabBarView(
            children: [
              loginScreen(),
              RegisterScreen(),
            ],
          ),
        ),
    ),
    );
  }
}