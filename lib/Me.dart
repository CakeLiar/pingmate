import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:work/Methods.dart';
import 'package:work/Settings.dart';
import 'package:work/TestAvatar.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import 'package:visibility_aware_state/visibility_aware_state.dart';
import 'package:work/providers/NavBarController.dart';

import 'avatar_scripts/Avataaar.dart';

class Me extends StatefulWidget {
  const Me({Key? key}) : super(key: key);

  @override
  State<Me> createState() => _MeState();
}

class _MeState extends VisibilityAwareState<Me> {

  FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;

  List<int> avatarI = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  bool Once = false;

  String topType = "LongHairBigHair", accessoriesType = "Blank",
      hairColor = "Blonde", facialHairType = "Blank",
      clotheType = "BlazerShirt", eyeType="Default",
      eyebrowType = "Default", mouthType = "Default",
      skinColor = "Light", clotheColor="Red";

  String mood = "-1";

  @override
  void onVisibilityChanged(WidgetVisibility visibility) {
    if (visibility == WidgetVisibility.VISIBLE) {
      setCurrentScreen("ChatRoom");
      print("VisibleEvent");
    }
    Future.delayed(Duration.zero, (){
      Provider.of<NavBarController>(context, listen: false).show();
    });
    super.onVisibilityChanged(visibility);
  }

  Future<void> getAvatar() async {
    print('hello world');
    avatarI = await getAvatarIs(_auth.currentUser);
    setState((){
      ;
    });
  }

  Future<void> setMood (String _mood) async {

    avatarI = await getAvatarIs(_auth.currentUser);
    saveAvatar(avatarI , _mood);
    saveAvatar(avatarI , _mood);
    sendEvent("Changed Mood");
    setState((){
      mood = _mood;
    });
  }

  Future<void> getMood () async {
    String _mood = "-1";
    print('getting mood');
    await firebaseFirestore.collection('users').doc(_auth.currentUser?.uid).get().then((value){
      if (value.exists) {
        Map<String, dynamic>mp = value.data() as Map<String, dynamic>;
        _mood=mp['emotion'];
        print(mp['emotion']);
        print ("couldn't get mood at allll");
        print(_mood);
        print(mp);
      } else {
        print("couldn't get mood at alll");
      }
    });

    if (_mood == '-1') {
      print ('couldn"t get mood');
      return;
    }
    setState((){
      mood = _mood;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (!Once) {
      getAvatar();
      getMood();
      Once = true;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("Me"),
        backgroundColor: Color(0xF0FF0054),
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          // Status bar color
          statusBarColor: Colors.transparent,

          // Status bar brightness (optional)
          statusBarIconBrightness: Brightness.light, // For Android (dark icons)
          statusBarBrightness: Brightness.dark, // For iOS (dark icons)
        ),

        actions: [
          true? Container(): Container(
            width: 70,
            height: 30,
            child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettingsScreen()));
                },
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(math.pi),
                  child: Icon(CupertinoIcons.gear_solid, color: Colors.white),
                )
            ),
          ),
        ],

        leading: Container(
          width: 30,
          height: 30,
          child: GestureDetector(
              onTap: () {
                logout(context);
                SystemNavigator.pop();
              },
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(math.pi),
                child: Icon(Icons.logout, color: Colors.white),
              )
          ),
        ),

      ),
      backgroundColor: Color(0xF0FF0054),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
                children: [
                  Container(
                    width: size.width,
                    height: size.width * 5/3,
                    child: Stack(
                      children: [
                        Stack(
                          children: [
                            Positioned(
                              top:size.width* (1/6),
                              child: Container(
                                height: size.width * (6/7),
                                width: size.width,
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  color: Color(0xFF6B7C71),
                                )
                              ),
                            ),
                            StreamBuilder<DocumentSnapshot>(
                              stream: firebaseFirestore.collection('users').doc(_auth.currentUser!.uid).snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot == null)
                                  return Container();
                                return Container(
                                    height: size.width,
                                    width:size.height,
                                    child: mood == '-1'? CupertinoActivityIndicator(color: Colors.white) : Avataaar (
                                      Is: snapshot.data!['avatarIs'],
                                      backgroundColor: Colors.transparent,
                                      radius: size.width,
                                      mood: snapshot.data!['emotion'],
                                    )
                                );
                              },

                            )
                          ]
                        ),

                        Positioned(
                          top: size.width-size.width/6.5,
                          child: Container(
                            width: size.width,
                            height:size.height/4,
                            child: Card (
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              shadowColor: Colors.transparent,
                              color: Color(0xFFB21640),
                              child: Column(
                                children: [
                                  Container(
                                    width: size.width/1.1,
                                    height: 60,
                                    child: Center(
                                      child: Text(
                                        "Flavour",

                                        style:TextStyle(
                                            fontSize:size.width/12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white
                                        ),
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width: size.width/3.5,
                                        child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children:[
                                              FloatingActionButton(
                                                onPressed: () {setMood("Cherry");},
                                                splashColor: Colors.transparent,
                                                foregroundColor: Colors.transparent,
                                                backgroundColor: (mood == "Cherry"?Colors.white : Color(0xFFEBC5CF)),
                                                child: Container(width: size.width/10, height: size.width/10, child:
                                                mood == "Cherry"? Image.asset('assets/images/cherry.png')
                                                    : Image.asset('assets/images/cherryS.png')
                                                ),
                                                elevation: 0,
                                                disabledElevation: 0,
                                                focusElevation: 0,
                                                hoverElevation: 0,
                                                highlightElevation: 0,
                                              ),

                                              SizedBox(height:2),

                                              Center(
                                                child: Text(
                                                  "Cherry",
                                                  style: TextStyle (
                                                    fontSize: 13,
                                                    color: mood == "Cherry"?Colors.white : Color(0xFFEBC5CF)
                                                  )
                                                ),
                                              ),
                                            ]
                                        ),
                                      ),

                                      Container(
                                        width: size.width/3.5,
                                        child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children:[
                                              FloatingActionButton (
                                                onPressed: () {setMood("Lemonade");},
                                                splashColor: Colors.transparent,
                                                foregroundColor: Colors.transparent,
                                                backgroundColor: (mood == "Lemonade"?Colors.white : Color(0xFFEBC5CF)),
                                                child: Container(width: size.width/10, height: size.width/10, child:
                                                mood == "Lemonade"? Image.asset('assets/images/lemon.png')
                                                    : Image.asset('assets/images/lemonS.png')
                                                ),
                                                elevation: 0,
                                                disabledElevation: 0,
                                                focusElevation: 0,
                                                hoverElevation: 0,
                                                highlightElevation: 0,
                                              ),
                                              SizedBox(height:2),
                                              Center(
                                                child: Text(
                                                    "Lemon",
                                                    style: TextStyle (
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w700,
                                                        color: mood == "Lemonade"?Colors.white : Color(0xE8E8E8FF)
                                                    )
                                                ),
                                              ),
                                            ]
                                        ),
                                      ),

                                      Container(
                                        width: size.width/3.5,
                                        child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children:[
                                              FloatingActionButton (
                                                onPressed: () {setMood("Espresso");},
                                                splashColor: Colors.transparent,
                                                foregroundColor: Colors.transparent,
                                                backgroundColor: (mood == "Espresso"?Colors.white : Color(0xFFEBC5CF)),
                                                child: Container(width: size.width/10, height: size.width/10, child:
                                                mood == "Espresso"? Image.asset('assets/images/espresso.png')
                                                    : Image.asset('assets/images/espressoS.png')
                                                ),
                                                elevation: 0,
                                                disabledElevation: 0,
                                                focusElevation: 0,
                                                hoverElevation: 0,
                                                highlightElevation: 0,
                                              ),

                                              SizedBox(height:2),

                                              Center(
                                                child: Text(
                                                    "Espresso",
                                                    style: TextStyle (
                                                        fontSize: 13,
                                                        color: mood == "Espresso"?Colors.white : Color(0xE8E8E8FF)
                                                    )
                                                ),
                                              ),
                                            ]
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 80,
                          left: 15,
                          child: Container(
                            width: 50,
                            height: 30,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => AvatarTest()));
                              },
                              child: Icon(
                                  CupertinoIcons.pencil_circle,
                                  color: Colors.white,
                                  size: 50
                              ),
                            ),
                          ),
                        ),
                      ]
                    ),
                  ),
                ]
          ),
        ),
      ),
    );
  }

  String getUrl () {

    topType = topTypes[avatarI[0]%topTypes.length];
    hairColor = hairColors[avatarI[1]%hairColors.length];
    accessoriesType = accessoriesTypes[avatarI[2]%accessoriesTypes.length];
    facialHairType = facialHairTypes[avatarI[3]%facialHairTypes.length];
    clotheType = clotheTypes[avatarI[4]%clotheTypes.length];
    clotheColor = clotheColors[avatarI[5]%clotheColors.length];
    skinColor = skinColors[avatarI[6]%skinColors.length];

    switch (mood) {
      case "Espresso":
        eyeType="Side";
        eyebrowType="Default";
        mouthType="Serious";
        break;
      case "Lemonade":
        eyeType = "Default";
        eyebrowType = "Default";
        mouthType = "Grimace";
        break;
      case "Cherry":
        eyeType = "Squint";
        eyebrowType = "Default";
        mouthType = "Eating";
        break;
      default:
        print("ERROR: invalid emotional state!");
        break;
    }

    return "https://avataaars.io/?clotheColor=$clotheColor&avatarStyle=Circle&topType=$topType&accessoriesType=$accessoriesType&hairColor=$hairColor&facialHairType=$facialHairType&clotheType=$clotheType&eyeType=$eyeType&eyebrowType=$eyebrowType&mouthType=$mouthType&skinColor=$skinColor";
  }

  Widget ParameterButton (int i, Size size, String txt) {
    return FloatingActionButton(
      onPressed: () {
        setState(() {
          avatarI[i]++;
        });
      },
      child: Container(
          height: size.height/14,
          width: size.width/1.2,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Colors.blue
          ),
          alignment: Alignment.center,
          child: Text(
              txt,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,

              )
          )
      ),
    );
  }
}
