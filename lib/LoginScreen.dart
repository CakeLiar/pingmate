import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:work/HomeScreen.dart';
import 'package:work/Methods.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool isLoading = false;

  void showError ({String r = ''}) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return BackdropFilter(
            filter: ImageFilter.blur(
              sigmaY: 2.5,
              sigmaX: 2.5,
            ),
            child: CupertinoAlertDialog(
              title: Text(
                  "Notice",
                  style: TextStyle(
                    fontSize: 22,
                    fontStyle: GoogleFonts.poppins().fontStyle,
                  )
              ),
              content: SingleChildScrollView(
                child: ListBody(
                  children: (r!='')? [
                    Text(r)
                  ] : [
                    Text("Please enter your correct email and password!\nIf you're from Syria: Please use a VPN for login"),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('OK',
                      style: TextStyle (
                        color: Color(0xFFFF0B6E),
                      )
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        }
    );
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;


    return Scaffold (
      backgroundColor: Color(0xFFFF0B6E),
      body: SingleChildScrollView(
        child: isLoading? Center(
            child: Container(
                height: size.height/20,
                width: size.height/20,
                child: CupertinoActivityIndicator(color: Colors.white)
            )
        ) : Center(
          child: Column(
              children:[
                SizedBox(
                  height: size.height/5,
                ),
                SizedBox(
                  height:size.height/50,
                ),

                Container(
                  width: size.width/1.3,
                  child: Text(
                      "PingMate",
                      style:TextStyle(
                          fontSize:size.width/7,
                          fontWeight: FontWeight.bold,
                        color: Colors.white
                      ),
                  ),
                ),

                SizedBox(height: 10),

                SizedBox(
                    height: size.height/2.5,
                ),

                Container(
                  width: size.width/1.2,
                  height: 50,
                  child: SignInButton(
                    Buttons.Google,
                    onPressed: () async {
                      setState ((){
                        isLoading = true;
                      });
                      print("SigningIn");
                      try {
                        await signInWithGoogle().then((user) {
                          if (user != null) {
                            print("Login Successful.");
                            showError(r:user!.displayName!);

                            setState(() {
                              isLoading = false;
                            });

                            sendEvent("Success Login");
                            Navigator.pushReplacement(context,
                                MaterialPageRoute(
                                    builder: (_) => HomeScreen()));
                          } else {
                            print("Error: User Null!!1!!11");
                            setState(() {
                              isLoading = false;
                              showError();
                              sendEvent("Failed Login");
                            });
                          }
                        }).catchError((e) {
                          print("ERROR SIGNING IN: $e");
                        });

                      } catch (e) {
                        e.printError();
                        showError(r:e.toString());
                        isLoading = false;
                        setState(() {

                        });
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),

                  ),
                ),

              ]),
        ),
      )
    );
  }



  Widget customButton (Size size) {
    return GestureDetector(
      onTap: () {

      },
      child: Container(
        height: size.height/14,
        width: size.width/1.2,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white
        ),
        alignment: Alignment.center,
        child: Text(
            "Login",
            style: TextStyle(
              color: Color(0xFFFF0B6E),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            )
        )
      ),
    );
  }
}
