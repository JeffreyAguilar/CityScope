import 'package:cityscope/home_page.dart';
import 'package:cityscope/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:cityscope/firebase/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: Auth().authStateChanges,
      builder: (context, snapshot) {
        if(snapshot.hasData){
          return const HomePage();
        }
        else {
          return const LoginPage();
        }
      },
    );
  }
}