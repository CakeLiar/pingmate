import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/parser.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:work/Methods.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:visibility_aware_state/visibility_aware_state.dart';
import 'package:work/providers/NavBarController.dart';
import 'package:work/providers/NotificationController.dart';
import 'package:work/providers/UserData.dart';

import 'avatar_scripts/Avataaar.dart';


class ChatRoom extends StatefulWidget {
  final Map<String, dynamic> userMap;
  final String chatroomId;
  bool notAFriend;



  ChatRoom({required this.chatroomId, required this.userMap, this.notAFriend = false});

  @override
  State<ChatRoom> createState() => _ChatRoomState();
}

class _ChatRoomState extends VisibilityAwareState<ChatRoom> with WidgetsBindingObserver {

  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late FirebaseAnalytics analytics;
  late FirebaseAnalyticsObserver observer;
  final TextEditingController _message = TextEditingController();

  List<List<dynamic>> chatList = [];

  bool isLoadingFriend = false;
  bool addedFriend = false;

  bool isWatching = false;

  bool longPressLongButton = false;

  int pingPoints = 0;

  void _getPingPoints () async {
    setState(() async {
      pingPoints = await getPingPoints(widget.chatroomId);
    });
  }

  void holdFunction () async {
    if (longPressLongButton) {
      sendHoldNotification(widget.userMap['token']);
      Future.delayed(Duration(seconds: 0, milliseconds: 500), () {
        holdFunction();
      });
      PingedLight();
    }
  }

  @override
  void onVisibilityChanged(WidgetVisibility visibility) {
    if (visibility == WidgetVisibility.VISIBLE) {
      setCurrentScreen("ChatRoom");
      print("VisibleEvent");

      Future.delayed(Duration.zero, (){
        Provider.of<NavBarController>(context, listen: false).hide();
      });

      updateLocalCurrentScreen(context, widget.userMap['uid']);

      updateWatchingChatroom(widget.chatroomId, true);
      print('opened screen');
    } else {
      updateLocalCurrentScreen(context, '');
      updateWatchingChatroom(widget.chatroomId, false);
    }

    super.onVisibilityChanged(visibility);
  }

  @override
  void dispose () {
    updateWatchingChatroom(widget.chatroomId, false);
    super.dispose();
  }

  @override
  void initState () {
    analytics = FirebaseAnalytics.instance;
    observer = FirebaseAnalyticsObserver(analytics: analytics);

    WidgetsBinding.instance.addObserver(this);

    Future.delayed(Duration.zero, () async {
      widget.notAFriend = !(await Provider.of<UserData>(context).checkFriend(widget.userMap['uid']));
    });

    //updateWatchingChatroom(widget.chatroomId, true);

    _getPingPoints();
    super.initState();

    print('STATUS');
    print((widget.userMap['status']==true&&widget.userMap['status']!='Unavailable'));
  }


  Color pingColorButton = Color(0xF0FF0979);

  void showCantTextDialog() async {
    showDialog (
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 2.5,
            sigmaY: 2.5,
          ),
          child: CupertinoAlertDialog(
            title: Text(
              'Notice',
              style: TextStyle(
                fontSize: 22,
                fontStyle: GoogleFonts.poppins().fontStyle,
              )
            ),
            content: Text(
              "To keep the conversations alive, you can only text others when they're online & in the same chat as you.",
              style: TextStyle(
                fontSize: 14,
                fontStyle: GoogleFonts.poppins().fontStyle,
              )
            ),
            actions: [
              TextButton(
                child: Text('OK',
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
      },
    );
  }

  void onPing() async {
    print ("initialized");
    String myemail = _auth.currentUser?.email as String;

    if (widget.userMap['token'] == 'purr') {
      sendPingCatEvent(myemail);
    } else {

      sendPingEvent(myemail, widget.userMap['email']);
      sendPingNotification(
          widget.userMap['token']
      );
      updatePingPoints(widget.chatroomId, pingPoints+1).then((_){
        setState((){
          pingPoints = pingPoints+1;
        });
      });
    }
  }

  void getMessages () async
  {

    var id = widget.chatroomId;
    var myuid = _auth.currentUser?.uid;
    var theiruid = widget.userMap['uid'];

    await _firestore.collection('chatrooms').doc(widget.chatroomId).get().then((value) {

      List<List<dynamic>> temp = [];
      Map<String, dynamic> mp = value.data() as Map<String, dynamic>;

      mp.forEach((first, second) {
        if (first != 'pingPoints' && first != widget.userMap['uid'] && first != _auth.currentUser!.uid)
          temp.add([second['sender']??'', second['message']??'', second['time'], second['uid']??'']);
      });

      /*mp.forEach((key, value) {
        temp.add([value['sender'].toString(), value['message'].toString()]);
      });*/
      setState((){
        int comparisonIndex = 2;
        chatList = temp
          ..sort((x, y) => (y[comparisonIndex] as dynamic)
              .compareTo((x[comparisonIndex] as dynamic)));
        chatList = chatList.take(min(3, temp.length)).toList();

        if (chatList.length > 0) {
          if (Timestamp
              .now()
              .seconds - chatList[0][2] > 5 * 60) {
            resetMessages();
          }
        }
      });
    }).catchError((e){
      print("Error: $e");
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    getMessages();


    updateWatchingChatroom(widget.chatroomId, true);

    return Scaffold (
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.userMap['name']),
        actions: [
          (addedFriend == true || widget.notAFriend == false)? Container()
            :  Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: GestureDetector(
              onTap: () {
                if (isLoadingFriend == true) {
                  return;
                }
                setState(() {
                  isLoadingFriend = true;
                });
                Provider.of<UserData>(context, listen: false).addFriend(widget.userMap);
              },
              child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(360)
                  ),
                  shadowColor: Colors.transparent,
                  color: Color(0xF0FF0054),
                  child: Container(
                    width: 50,
                    height: 50,
                    child: isLoadingFriend? CupertinoActivityIndicator(color: Colors.white): Center(
                      child: Text(
                          '+',
                          style: TextStyle(
                            fontSize: 25,
                            color: Colors.white,
                          )
                      ),
                    ),
                  )
                ),
              )
          ),
        ]
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                MediaQuery.of(context).viewInsets.bottom!=0? Container() : Container(
                  height: (size.width/3.5) ,
                  width: isWatching? size.width : (size.width/3.5),
                  child: Stack(
                      children: [
                        Positioned(
                          top: size.width/6,
                          child: Container(
                              height: size.width/(3.5),
                              width: isWatching? size.width : size.width/3.5,
                              child: Card(
                                shadowColor: Colors.transparent,
                                margin: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(isWatching?0:20.0),
                                ),
                                color: const Color(0xFFFFABC8),
                              )
                          ),
                        ),
                        Container(
                            height: size.width/3.5,
                            width:isWatching?size.width:size.width/3.5,
                            child: widget.userMap['nameS']!='catt'?
                            Avataaar(
                              radius: size.width/3.5,
                              backgroundColor: Colors.transparent,
                              Is: (widget.userMap['avatarIs'] ?? [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
                              mood: widget.userMap['emotion'],
                              awake: (widget.userMap['status']==true&&widget.userMap['status']!='Unavailable'),
                            ) : Image.asset(
                                'assets/images/cattt.png'
                            )
                        ),
                      ]
                  ),
                ), //Avatar
                MediaQuery.of(context).viewInsets.bottom != 0? Container() : Center(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: _firestore.collection('pingPointsChatroom').doc(widget.chatroomId).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.data != null) {
                        try {
                          pingPoints = snapshot.data!['pingPoints'];
                        } catch(e) {
                          print('error! $e');
                          pingPoints = 0;
                        }
                      } else {
                        pingPoints = 0;
                      }
                      if (pingPoints != 0)
                        return Text(
                            '👉 ${pingPoints.toString()}',
                            style: TextStyle(
                              fontWeight: FontWeight.w100,
                              color: Color(0xFFF58FA7),
                              fontSize: 14,
                            )
                        );
                      return Container();
                    },
                  ),
                ),
              ]
            ),


            Column(
              children: [
                isWatching? Container(
                  width:size.width,
                  height: 3*(45+25),
                  child: ListView.builder (
                    reverse: true,
                    physics: BouncingScrollPhysics(),
                    itemCount: chatList.length,
                    itemBuilder: (BuildContext context, int index) {
                      return myCard(size, chatList[index][0], chatList[index][1], chatList[index][3], index);
                    },
                  ),
                ) : Container(
                  width:size.width,
                  height: 45+25,
                  child: myCard(size, '', '', '', -1),
                ),
                SizedBox(height: 15),

                widget.userMap['nameS']=='catt'?Container():Center(
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: _firestore.collection('users').doc(widget.userMap['uid']).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.data != null) {

                          widget.userMap['status'] = snapshot.data!.get('status');

                          if (snapshot.data!.get('status') == true) {
                            if (isWatching) {
                              return Text(
                                '${widget.userMap['name']} is looking at you.',
                                style: TextStyle(
                                  color: Color(0xFF717171),
                                )
                              );
                            }
                            return Text(
                              '${widget.userMap['name']} is online.',
                              style: TextStyle(
                                color: Color(0xFF717171),
                              )
                            );
                          }
                          return Text(
                            '${widget.userMap['name']} is sleeping.',
                            style: TextStyle(
                              color: Color(0xFF717171),
                            )
                          );
                        } else {
                          return Text(
                            '${widget.userMap['name']} is sleeping.',
                            style: TextStyle(
                              color: Color(0xFF717171),
                            )
                          );
                        }
                      },
                    )
                ),

                widget.userMap['nameS']=='catt'?Container():StreamBuilder<DocumentSnapshot>(
                  stream: _firestore.collection('chatrooms').doc(widget.chatroomId).snapshots(),
                  builder: (context, snapshot) {
                    print('hellowing');
                    if (snapshot.data != null) {
                      try {
                        if (snapshot.data![widget.userMap['uid']]) {
                          isWatching = true;
                          return Container();
                        } else {
                          isWatching = false;
                          return Container();
                        }
                      } catch(e) {
                        print('erroring: $e');
                        return Container();
                      }
                    }
                    return Container();
                  },
                ),

                Container(
                  width: size.width,
                  height: 160 - ((!isWatching && (MediaQuery.of(context).viewInsets.bottom==0))?0:80),
                  child: Card(
                    margin: EdgeInsets.zero,
                    color: Color(0xFFDBDBDB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(20),
                          topLeft: Radius.circular(20),
                          bottomRight: Radius.circular(0),
                          bottomLeft: Radius.circular(0)),
                    ),
                    child: Column(
                      verticalDirection:  VerticalDirection.down,
                      children: [
                        isWatching? Container() : Padding (
                          padding: isWatching? EdgeInsets.only(bottom: 8) : EdgeInsets.only(top: 8),
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              MediaQuery.of(context).viewInsets.bottom!=0? Container()  :Container(
                                height: longPressLongButton? 80 : 80,
                                width: longPressLongButton? 80 : size.width/1.1,
                                child: GestureDetector(
                                  onTapDown: (_) {
                                    setState((){
                                      pingColorButton = Color(0xFFD02075);
                                    });
                                  },
                                  onTapCancel: () {
                                    setState((){
                                      pingColorButton = Color(0xF0FF0979);
                                    });
                                  },
                                  onLongPressDown: (_) {
                                    print('longp down');
                                    setState((){
                                      longPressLongButton = true;
                                      pingColorButton = Color(0xFFD02075);
                                    });
                                    holdFunction();
                                  },
                                  onLongPressUp: (){
                                    print('longp up');
                                    setState(() {
                                      longPressLongButton = false;
                                    });
                                  },
                                  onLongPressCancel: () {
                                    print('longp cancel');
                                    setState(() {
                                      longPressLongButton = false;
                                    });
                                  },
                                  onTapUp: (_) {
                                    print("pressed");
                                    Pinged();
                                    setState((){
                                      pingColorButton = Color(0xF0FF0979);
                                    });

                                    //sendEvent();
                                    onPing();
                                  },
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(longPressLongButton?360:20.0),
                                    ),
                                    color: pingColorButton,//Color(0xF0FF0054),
                                    child: Container(
                                        child: Center(
                                          child: Text(
                                              longPressLongButton?"":"Ping",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 30,
                                                  fontWeight: FontWeight.bold
                                              )
                                          ),
                                        )
                                    ), //declare your widget here
                                  ),
                                ),
                              ),



                              longPressLongButton? Center(child: Container(width: 80, height: 80, child:Transform.rotate(angle: 180,
                                  child: Container(width: 80, height: 80,child: CircularProgressIndicator(color: pingColorButton))))) : Container(),
                              longPressLongButton? Center(child: Container(width: 80, height: 80, child:CircularProgressIndicator(color: pingColorButton))) : Container(),
                              longPressLongButton? Center(child: Container(width: 80, height: 80, child:Transform.rotate(angle: 90,
                              child: Container(width: 20, height: 20,child: CircularProgressIndicator(color: Colors.white,))))) : Container(),
                              longPressLongButton? Center(child: Container(width: 80, height: 80, child:Transform.rotate(angle: 135,
                                  child: Container(width: 20, height: 20,child: CircularProgressIndicator(color: Colors.white,))))) : Container(),
                            ],
                          ),
                        ),
                        Container(
                          width: size.width/1.1,
                          height: 62,
                          child: Card(
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            color: Color(0xFFFFFFFF),
                            child: Container(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12, left: 12),
                                child: TextField(
                                  textAlignVertical: TextAlignVertical.center,
                                  controller: _message,
                                  cursorColor: Color(0xF0FF0979),
                                  style: TextStyle(
                                    color: Color(0xF0FF0979),
                                  ),
                                  maxLength: 30,
                                  enabled: true,
                                  readOnly: !isWatching,
                                  onTap: () {
                                    print('tapped lol');
                                    if (!isWatching) {
                                      showCantTextDialog();
                                    }
                                  },
                                  decoration: InputDecoration(
                                    helperMaxLines: 0,
                                    errorMaxLines: 0,
                                    counterText: "",
                                    hintText: isWatching?"Type Message":"Text disabled",

                                    hintStyle: TextStyle(
                                      color: Colors.grey,
                                    ),
                                    border: UnderlineInputBorder( borderSide: BorderSide(color: Colors.transparent)),
                                    enabledBorder: UnderlineInputBorder( borderSide: BorderSide(color: Colors.transparent)),
                                    disabledBorder: UnderlineInputBorder( borderSide: BorderSide(color: Colors.transparent)),
                                    focusedBorder: UnderlineInputBorder( borderSide: BorderSide(color: Colors.transparent)),
                                    suffix: !isWatching? Container(
                                      width: 50,
                                      height: 5,
                                    ) : Container(
                                      width: 40,
                                      height: 40,
                                      child: GestureDetector(
                                        onTap: () {
                                          sendMessage(_message.text);
                                        },
                                        child: Icon(
                                          CupertinoIcons.arrowtriangle_up_circle_fill,
                                          color: pingColorButton,
                                        ),
                                      ),
                                    )
                                  ),
                                  onSubmitted: (_message) {
                                    sendMessage(_message);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void resetMessages () async {
    await _firestore.collection('chatrooms').doc(widget.chatroomId).delete()
        .then((_) {
      getMessages();
    }).catchError((e) {
      print("ERRROR:");
      print(e);
    });
  }

  void sendMessage (String toSend) async
  {
    _message.clear();
    var myuid = _auth.currentUser?.uid;



    //myMessage = toSend;
    //myMessageTime = Timestamp.now().seconds;

    String nowNumber ='${Timestamp.now().toDate().year}${Timestamp.now().toDate().month}${Timestamp.now().toDate().day}${Timestamp.now().toDate().hour}${Timestamp.now().toDate().minute}${Timestamp.now().toDate().second}${Timestamp.now().toDate().millisecond}';
    await _firestore.collection('chatrooms').doc(widget.chatroomId).set({
      "$myuid$nowNumber": {
        "sender": "${_auth.currentUser!.displayName}",
        "message":"$toSend",
        "time":Timestamp.now().seconds,
        'uid': _auth.currentUser!.uid,
      },
    }, SetOptions(merge: true))
    .then((_) {
      getMessages();
    }).catchError((e) {
      print("ERRROR:");
      print(e);
    });
    //sendMessageNotification(widget.userMap['token'], toSend);
  }

  Widget myCard (Size size, String sender, String text, String uid, index) {
    return Column(
      children: [
        (index!=chatList.length-1 && chatList[index+1][0]==sender)?SizedBox(height:5):Container(
          height: 25,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 26.0),
              child: Text(
                (uid== _auth.currentUser!.uid?'Me':sender),
                style: TextStyle(
                  color: uid==_auth.currentUser!.uid?Color(0xF0FF0979):Color(0xFFF58FA7),
                )
              ),
            ),
          ),
        ),
        Container(
          height: 45,
          child: Card(
            margin: EdgeInsets.zero,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(8),
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            color: Colors.white,

            child: Container(
                width: size.width/1.1,
                height: 45,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      index==-1? 'Chat is hidden' : text,
                      style: TextStyle(
                        color: Color(0xFF717171),
                        fontWeight: FontWeight.w300,
                        fontSize: 17,
                      ),
                    ),
                  ),
                )
            ),
          ),
        ),
      ],
    );
  }
}

