import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:work/providers/UserData.dart';

import 'avatar_scripts/Avataaar.dart';

class SettingsScreen extends StatefulWidget {

  SettingsScreen({Key? key}) : super(key: key);
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  final nameInput = TextEditingController();

  bool isLoadingUsername = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings")
      ),
      body: Column(
        children: [
          SizedBox(
            height: 30,
          ),
          Container(
            width: size.width,
            child: Padding(
              padding: EdgeInsets.only(left: size.width*.1),
              child: Text(
                "Change username",
                textAlign: TextAlign.left,
              ),
            ),
          ),

          Container(
              height: size.height/13,
              width: size.width/1.2,
              alignment: Alignment.center,
              child: Card(
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                color: Color(0xF0FFFFFF),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12, left: 12),
                  child: TextField(
                    textAlignVertical: TextAlignVertical.center,
                    controller: nameInput,
                    cursorColor: Color(0xF0FF0054),
                    style: TextStyle(
                      color: Color(0xF0FF0054),
                    ),

                    maxLength: 25,

                    decoration: InputDecoration(
                      hintText: "Enter new username",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: UnderlineInputBorder( borderSide: BorderSide(color: Colors.transparent)),
                      enabledBorder: UnderlineInputBorder( borderSide: BorderSide(color: Colors.transparent)),
                      disabledBorder: UnderlineInputBorder( borderSide: BorderSide(color: Colors.transparent)),
                      focusedBorder: UnderlineInputBorder( borderSide: BorderSide(color: Colors.transparent)),
                      counterText: ""
                    ),
                    onChanged: (_) {
                      onChange();
                    },
                  ),
                ),
              )
          ),
          Card(
            shadowColor: Colors.transparent,
            color: Color(0xF0FF0054),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20, top: 10, bottom: 10),
              child: isLoadingUsername? CupertinoActivityIndicator() : Text(
                "Change",
                style: TextStyle(
                  color: Colors.white,
                )
              ),
            ),
          ),
        ],
      )
    );
  }

  void onChange() {

  }
}
