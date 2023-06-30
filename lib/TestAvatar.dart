import 'dart:core';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:work/LoginScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:work/Methods.dart';
import 'package:visibility_aware_state/visibility_aware_state.dart';
import 'package:work/providers/NavBarController.dart';

import 'avatar_scripts/Avataaar.dart';
import 'avatar_scripts/fluttermojiCustomizer.dart';

class AvatarTest extends StatefulWidget {
  const AvatarTest({Key? key}) : super(key: key);

  @override
  State<AvatarTest> createState() => _AvatarTestState();
}

class _AvatarTestState extends VisibilityAwareState<AvatarTest> {

  List<int> avatarI = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  bool Once = false;
  bool saving = false;
  bool gotAvatars = false;

  String topType = "LongHairBigHair", accessoriesType = "Blank",
      hairColor = "Blonde", facialHairType = "Blank",
      clotheType = "BlazerShirt", eyeType="Default",
      eyebrowType = "Default", mouthType = "Default",
      skinColor = "Light", clotheColor="Red";

  String mood = "-1";

  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  @override
  void onVisibilityChanged(WidgetVisibility visibility) {
    if (visibility == WidgetVisibility.VISIBLE) {
      setCurrentScreen("EditAvatar");
      print("VisibleEvent");
    }

    Future.delayed(Duration.zero, (){
      Provider.of<NavBarController>(context, listen: false).hide();
    });


    super.onVisibilityChanged(visibility);
  }

  Future<void> getMood () async {
    String _mood = "-1";
    print('getting mood');
    await firebaseFirestore.collection('users').doc(_auth.currentUser?.uid).get().then((value){
      if (value.exists) {
        Map<String, dynamic>mp = value.data() as Map<String, dynamic>;
        _mood=mp['emotion'];
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


  void getAvatar () async {
    print("GETTING AVATARS");
    avatarI = await getAvatarIs(_auth.currentUser);
    print(avatarI);
    setState((){
      gotAvatars = true;
    });
  }

  @override
  void initState () {
    getAvatar();
    getMood();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text("Customize"),
        leading: Container(
            width: 80,
            height: 30,
            child: GestureDetector(
              onTap: () async {
                Navigator.of(context).pop();
              },
              child: Icon(
                color: Colors.black,
                CupertinoIcons.back,
              ),
            )
        ),
      ),
      body: !gotAvatars?
          Center(
            child: Container(
              width: size.width,
              child: CupertinoActivityIndicator(color: Color(0xF0FF0054))
            ),
          )
          : Column(
            children: [
              Container(
                height: size.width* 5/7,
                child: Stack(
                    children: [
                      Positioned(
                        top: size.width * 2/7,
                        child: Container(
                            height: size.width * (5/7),
                            width: size.width,
                            child: Card(
                              shadowColor: Colors.transparent,
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              color: Color(0xFFDFDDDE)  ,
                            )
                        ),
                      ),
                      Container(
                        height: size.width,
                        width:size.height,
                        child: true? Avataaar(radius: size.width, backgroundColor: Colors.transparent, Is: avatarI, mood: mood) : SvgPicture.network(
                            getUrl()
                        ),
                      ),
                    ]
                ),
              ),

              Expanded(
                child: FluttermojiCustomizer(
                    updateIndex: (int s, int n) {
                      setState((){
                        avatarI[s] = n;
                        print("SHOULD UPDATE INDEX $n with $s");
                        print("SAVING AVATAR");
                        saveAvatar(avatarI, '-1');
                      });
                    },
                ),
              ),
            ]
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

  Widget ParameterButton (int i, Size size, String txt, String _type) {
    return GestureDetector(
      onTap: () {
        setState(() {
          avatarI[i]++;
        });

        saveAvatar(avatarI, mood);
      },
      child: Container(
          height: size.height/12,
          width: size.width/1.1,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Text(
                      _type +":",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      )
                  ),
                ),
                Center(
                  child: Text(
                      txt,
                      style: TextStyle(
                        color: Color(0xF0FF0054),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      )
                  ),
                ),
              ]
            ),
          )
      ),
    );
  }
}
