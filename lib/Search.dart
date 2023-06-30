import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'package:work/Authenticate.dart';
import 'package:work/ChatRoom.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:work/Me.dart';
import 'package:work/TestAvatar.dart';
import 'package:work/providers/NavBarController.dart';
import 'package:work/providers/UserData.dart';
import 'Methods.dart';
import 'package:visibility_aware_state/visibility_aware_state.dart';
import 'package:flutter_sms/flutter_sms.dart';

import 'dart:ui' as ui;
import 'package:share_plus/share_plus.dart';

import 'avatar_scripts/Avataaar.dart';


class Search extends StatefulWidget {
  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends VisibilityAwareState<Search> {

  Map<String, dynamic> userMap = Map<String, dynamic>();
  bool isLoading = false;
  List<Map<String, dynamic>> searchMap_list = [];
  List<bool> selectedIndex = [];
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  Map<String, Color> emotionColor = {"Cherry":Colors.green,
                                     "Lemonade": Colors.yellowAccent,
                                     "Espresso": Colors.redAccent};

  List<dynamic> friend_list = [];
  List<Map<String, dynamic>> friendMap_list = [];


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

  void showPingDialog () {
    TextEditingController _phoneNumber = TextEditingController();
    print("hello");
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setState){
                return BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                  child: CupertinoAlertDialog(
                    title: Text(
                      'SMS Ping',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontStyle: GoogleFonts.poppins().fontStyle
                      ),
                    ),
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: [
                          SizedBox(height: 30,),
                          Text(
                            'Phone number'
                          ),
                          CupertinoTextField(
                            keyboardType: TextInputType.phone,
                            controller: _phoneNumber,
                            style: TextStyle(
                              color: Color(0xFFFF0B6E),
                              fontStyle: GoogleFonts.poppins().fontStyle,
                            ),
                            cursorColor: Color(0xFFFF0B6E),
                          ),

                          SizedBox(
                            height: 10,
                          ),

                          Text(
                            'Ping your friends via SMS and allow them to Ping you back when they download the app!',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: GoogleFonts.poppins().fontStyle,
                            )
                          )
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: Text(
                          'PING',
                          style: TextStyle (
                            color: Color(0xFFFF0B6E),
                            fontWeight: FontWeight.bold,
                            fontStyle: GoogleFonts.poppins().fontStyle,
                          )
                        ),
                        onPressed: () async {
                          if (_phoneNumber.text == null)
                            return;

                          if (await Permission.sms.request().isGranted)
                            print("CAN SEND SMS");
                          else
                            print("DENIED SMS");

                          String _result = await sendSMS(
                              message: "PINGED by ${_auth.currentUser!.displayName}, ping them back!\n bit.ly/PingMate",
                              recipients: [_phoneNumber.text])
                              .catchError((e) {
                            print("SENDING SMS ERROR: $e");
                          });
                          Pinged();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
              }
          );
        }
    );
  }

  void showSecondPingDialog () {
    Share.share("PINGED by ${_auth.currentUser!.displayName}, ping them back!\n bit.ly/PingMate");
  }

  final TextEditingController _search = TextEditingController();

  Future<void> onSearch () async {
    sendSearchEvent(_search.text, friend_list.length);
    selectedIndex.clear();
    FirebaseFirestore _firestore = FirebaseFirestore.instance;
    setState( () {
      searchMap_list.clear();
      print ("Loading search");
    });

    await _firestore.collection('users')
        .where("nameS", isGreaterThanOrEqualTo : _search.text.replaceAll(" ", "").toLowerCase())
        .where("nameS", isLessThanOrEqualTo : _search.text.replaceAll(" ", "").toLowerCase() + '\uf8ff').limit(8)
        .get().then((value) {
      print("Hi");

      if (value.docs.isEmpty) {
        print("second hi");
        return;
      }

      for (int i = 0; i < value.docs.length; i++) {
        print ("Result");
        print(value.docs[i].data());
        print(friend_list);
        selectedIndex.add(friend_list.contains(value.docs[i].data()['uid']));
        searchMap_list.add(value.docs[i].data());
      }

      print(userMap);
    });
  }

  void setUp () async {
    setState((){
      isLoading = true;
    });
    //await getFriends();

    //await Provider.of<UserData>(context, listen: false).getFriends();

    setState((){
      friend_list = Provider.of<UserData>(context, listen: false).friend_list;
      friendMap_list = Provider.of<UserData>(context, listen: false).friendMap_list;
    });

    await onSearch();

    setState((){

      isLoading = false;
      print('finished setting up');
    });
  }

  @override
  void initState() {

    super.initState();

    setUp();

    setState((){
      searchMap_list.clear();
    });

    firebaseMessaging.getToken().then((value) {
      print(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    print("my search $searchMap_list");
    print("my search $friendMap_list");
    for (int i = 0; i < searchMap_list.length; i++)
    {
      print("Friends: ${searchMap_list[i]['uid']}");
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Explore")
      ),
        body: false? Container() :
        Column (
          children: [
            Container(
                height: size.height/13,
                width: size.width/1.2,
                alignment: Alignment.center,
                child: Card(
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  color: Color(0xF0FFFFFF),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12, left: 12),
                    child: TextField(
                      textAlignVertical: TextAlignVertical.center,
                      controller: _search,
                      cursorColor: Color(0xF0FF0054),
                      style: TextStyle(
                        color: Color(0xF0FF0054),
                      ),

                      decoration: InputDecoration(
                        prefixIcon: Icon(CupertinoIcons.search),
                        hintText: "Search",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: UnderlineInputBorder( borderSide: BorderSide(color: Colors.transparent)),
                        enabledBorder: UnderlineInputBorder( borderSide: BorderSide(color: Colors.transparent)),
                        disabledBorder: UnderlineInputBorder( borderSide: BorderSide(color: Colors.transparent)),
                        focusedBorder: UnderlineInputBorder( borderSide: BorderSide(color: Colors.transparent)),
                      ),
                      onChanged: (_) {
                        onSearch();
                      },
                    ),
                  ),
                )
            ),

            SizedBox(
              height: size.height/50,
            ),

            (isLoading || Provider.of<UserData>(context, listen: false).isGettingFriends)? Container(
              width: size.width,
              height: size.height/1.7,
              child: Center(
                  child: Container (
                    height: size.height/20,
                    width: size.height/20,
                    child: CupertinoActivityIndicator(color: Color(0xF0FF0054)),
                  )
              ),
            ) :
            searchMap_list.length>0?
            Expanded(
              child: Container(
                width: size.width,
                child: ListView.builder(
                  shrinkWrap : true,
                  itemCount: searchMap_list.length+2,
                  itemExtent: 80,
                  padding: EdgeInsets.only(top:0),
                  physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  scrollDirection: Axis.vertical,
                  itemBuilder: (BuildContext context, int indx) {
                    int index = indx-2;
                    return Container(
                      width: size.width,
                      height: 100,
                      child: GestureDetector(
                        onTap: () {
                          if (indx == 0) {
                            showPingDialog();
                            return;
                          }
                          if (indx == 1) {
                            showSecondPingDialog();
                            return;
                          }
                          if (selectedIndex[index])
                            return;
                          Pinged();

                          Provider.of<UserData>(context, listen: false).addFriend(searchMap_list[index]);

                          selectedIndex[index] = true;
                          setState((){});
                        },

                        child: (indx == 0)? addFriendCard()
                          : (indx == 1)? sharePing() : Card(
                          margin: EdgeInsets.only(top: 2, bottom: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          color: (selectedIndex[index]?Color(0xFFEEEEEE):Colors.white),
                          shadowColor: Colors.transparent,
                          child: Row(
                            children: [
                              SizedBox(width: 10),
                              Container(
                                  width: 63,
                                  height: 63,
                                  child: Avataaar(
                                    Is:searchMap_list[index]['avatarIs'] ?? [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                                    radius: 63,
                                    backgroundColor: Colors.transparent,
                                    mood: searchMap_list[index]['emotion'] ?? 'Espresso',
                                  )
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      child: Text(
                                        searchMap_list[index]['name'],
                                        style: const TextStyle(
                                          fontSize: 13,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 10.0),
                                      child: Card(
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        color: Color(0xFFEFEFEF),
                                        child: Padding(
                                          padding: EdgeInsets.only(right: 10, left: 10, top: 3, bottom: 3),
                                          child: Text(
                                            selectedIndex[index]?'Added': "Add"
                                          )
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              )
                            ]
                          )
                        ),
                      ),
                    );
                  },
                ),
              ),
            ) : Container(),

          ],
        )
    );
  }

  Widget sharePing() {
    return Card(
      margin: EdgeInsets.only(top: 2, bottom: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      color: Colors.white,
      shadowColor: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 50.0),
            child: Text(
              'Share via WhatsApp',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          Padding(
              padding: const EdgeInsets.only(right: 30.0),
              child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(360)
                  ),
                  shadowColor: Colors.transparent,
                  color: Color(0xF0FF0054),
                  child: Container(
                    width: 50,
                    height: 50,
                    child: Center(
                        child: Icon(
                            CupertinoIcons.arrow_right,
                            color: Colors.white
                        )
                    ),
                  )
              )
          ),
        ],
      )
    );
  }

  Widget addFriendCard() {
    return Card(
        margin: EdgeInsets.only(top: 2, bottom: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        color: Colors.white,
        shadowColor: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 50.0),
              child: Text(
                'Ping via SMS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            Padding(
                padding: const EdgeInsets.only(right: 30.0),
                child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(360)
                    ),
                    shadowColor: Colors.transparent,
                    color: Color(0xF0FF0054),
                    child: Container(
                      width: 50,
                      height: 50,
                      child: Center(
                        child: Icon(
                          CupertinoIcons.arrow_right,
                          color: Colors.white
                        )
                      ),
                    )
                )
            ),
          ],
        )
    );
  }

  Widget field(Size size, String hintText, IconData icon, TextEditingController cont) {
    return Container(
        height: size.height/15,
        width: size.width/1.3,
        alignment: Alignment.center,
        child: TextField(
          controller: cont,
          cursorColor: Colors.white,
          obscureText: false,
          style: TextStyle(color: Colors.white),

          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Color(0xfff4b3c8)),

          ),
        )
    );
  }
}
