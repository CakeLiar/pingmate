import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


class LoginScreenTest extends StatefulWidget {
  @override
  _LoginScreenTestState createState() => _LoginScreenTestState();
}

class _LoginScreenTestState extends State<LoginScreenTest> {

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
        width: 414,
        height: 896,
        decoration: BoxDecoration(
          borderRadius : BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          gradient : LinearGradient(
              begin: Alignment(6.123234262925839e-17,1),
              end: Alignment(-1,6.123234262925839e-17),
              colors: [Color.fromRGBO(255, 11, 70, 1),Color.fromRGBO(255, 10, 128, 1)]
          ),
        ),
        child: Column(
            children: <Widget>[
              SizedBox(width: 0, height: size.height/5),
              Text('PingMate', style:TextStyle(color: Colors.white, fontSize: 50)),
              SizedBox(width: 0, height: size.height/2000),
              Text('Are you ready to ping some mates?', style:TextStyle(color: Colors.white, fontSize: 15)),
            ]
        )
    );
  }
}
