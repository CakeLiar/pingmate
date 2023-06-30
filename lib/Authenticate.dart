import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:work/HomeScreen.dart';
import 'package:work/LoginScreen.dart';
import 'package:work/TestAvatar.dart';

class Authenticate extends StatelessWidget {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return (_auth.currentUser != null?HomeScreen():LoginScreen());
  }
}