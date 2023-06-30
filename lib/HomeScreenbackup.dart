import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:work/Authenticate.dart';
import 'package:work/ChatRoom.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:work/Me.dart';
import 'package:work/NotificationsSection.dart';
import 'package:work/TestAvatar.dart';
import 'package:work/providers/NavBarController.dart';
import 'package:work/providers/NotificationController.dart';
import 'package:work/providers/UserData.dart';
import 'Methods.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:visibility_aware_state/visibility_aware_state.dart';

import 'Search.dart';
import 'avatar_scripts/Avataaar.dart';


class HomeScreenExtra extends StatefulWidget {
  @override
  State<HomeScreenExtra> createState() => _HomeScreenExtraState();
}


class _HomeScreenExtraState extends VisibilityAwareState<HomeScreenExtra> {
  Map<String, dynamic> userMap = Map<String, dynamic>();
  bool isLoading = false;
  List<dynamic> friend_list = [];
  bool friendsUpdated = false;
  String myToken = "";
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  Map<String, Color> emotionColor = {"Cherry":Color(0xFF39c56c),
                                     "Lemonade": Color(0xFFFFCE01),
                                     "Espresso": Color(0xffff0533),
                                     "Purr": Color(0xffb533e5)};

  List<Map<String, dynamic>> notifications = [];
  RefreshController _refreshController = RefreshController(initialRefresh: false);

  @override
  void onVisibilityChanged(WidgetVisibility visibility) {
    if (visibility == WidgetVisibility.VISIBLE) {
      setCurrentScreen("HomeScreen");
      print("VisibleEvent");
    }
    Future.delayed(Duration.zero, (){
      Provider.of<NavBarController>(context, listen: false).show();
    });
    super.onVisibilityChanged(visibility);
  }


  int min (int x, int y) {
    return x<y?x:y;
  }

  void setToken () async {
    FirebaseMessaging.instance.getToken().then((token) {
      myToken = token!;
      FirebaseFirestore.instance.collection('users').doc(_auth.currentUser?.uid).set({
        'token': token
      }, SetOptions(merge: true));
    });
  }


  getFriends () async {

    print('getting friends');
    await Provider.of<UserData>(context, listen: false).getFriends();

    print('got: ${Provider.of<UserData>(context, listen: false).friendMap_list}');

    setState((){
      _refreshController.refreshCompleted();
    });
  }

  void initState() {
    setToken();

    print ("hi");
    super.initState();


    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {

      print ("Got message in foreground");

      if (message.data['type'] == 'hold') {
        PingedLight();
        return;
      }

      if (message.data['type'] == 'ping') {


        var sender_name = message.data['sender-name'];
        var sender_uid = message.data['sender-uid'];

        if (getLocalCurrentScreen(context) != message.data['sender-uid'])
          NotificationController.createNewNotification (
            'PINGED', "$sender_name pinged you!", sender_name, sender_uid, chatRoomId(_auth.currentUser!.uid, sender_uid));

        Pinged();

        Map<String, dynamic> sender_userMap = {};

        await _firestore
            .collection('users')
            .doc(sender_uid)
            .get().then((value) {
          Map<String, dynamic> data = value.data() as Map<String, dynamic>;
          sender_userMap = data;
        });

        if (sender_userMap == {}) {
          print("ERROR: usermap null, cannot open snackbar");
        }

        if (getLocalCurrentScreen(context) != message.data['sender-uid']) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0)
                  ),
                ),
                backgroundColor: Colors.black,
                content: Container(
                  height: 50,
                  child: Center(
                    child: Text(
                      "$sender_name pinged you!",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      )
                  ),
                  ),
                ),
                action: SnackBarAction(
                  label: "Ping",
                  textColor: Color(0xF0FF0054),
                  onPressed: () {
                    String roomId = chatRoomId(
                        _auth.currentUser?.uid, sender_userMap['uid']);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) =>
                        ChatRoom(
                          chatroomId: roomId,
                          userMap: sender_userMap,
                          notAFriend: true,
                        )
                        //HomeScreenExtra()
                      )
                    );
                  },
                ),
              )
          );
        }
      }


    });
    // firebaseMessaging.getToken().then((value) { print(value);});
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title : Text(
          "PingMate",
        ),
        leadingWidth: 70,
        leading: Container(
          child: GestureDetector(
            onTap: () {
              /// Open notifications tab
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => NotificationsSection(notifications: notifications)));
            },

            child: StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('users').doc(_auth.currentUser!.uid).snapshots(),
              builder: (context, snapshot) {
                List<Map<String, dynamic>> temp = [];
                if (snapshot.data != null) {
                  try {
                    /// The notification is in the following form: ['command', 'by who', 'date']
                    snapshot.data!['notifications'].forEach((_){
                      temp!.add(_);
                    });
                  } catch(e) {
                    print('erro1r: $e');
                  }
                } else {
                  Future.delayed(Duration(milliseconds: 20), () async {

                  });
                  getFriends();
                  print('error, invalid data');
                }


                if (temp != null)
                  notifications = temp!;
                if (temp != null && temp.length > 0) {
                  return Stack(
                    children: [
                      Center(
                          child: Card(
                            shadowColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(360)
                            ),
                            child: Container(
                              width: 40,
                              height: 40,
                              child: Icon(
                                  CupertinoIcons.bell_fill
                              ),
                            ),
                          )
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: CircleAvatar(
                          radius: 7,
                          backgroundColor: Colors.red,
                        ),
                      )
                    ],
                  ); //Bell with notifications
                }

                return Center(
                    child: Icon(CupertinoIcons.bell_fill)
                ); // Bell with no notifications
              },
            ),
          ),
        ),
      ),
        body: Column (
          children: [

            Expanded(
              child: Container(
                width: size.width,
                child: SmartRefresher(
                  controller: _refreshController,
                  onRefresh: getFriends,
                  enablePullDown: true,
                  physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  enablePullUp: false,
                  header: TwoLevelHeader(
                    iconPos: IconPosition.bottom,
                    refreshingIcon: CupertinoActivityIndicator(color: Colors.white),
                    failedIcon : Container(),
                    completeIcon : Container(),
                    idleIcon : const Icon(CupertinoIcons.arrow_down, color: Colors.white),
                    releaseIcon : const Icon(CupertinoIcons.refresh_thick, color: Colors.white),
                    releaseText: "",
                    refreshingText: "",
                    canTwoLevelText: "",
                    completeText: "",
                    failedText: "",
                    idleText: "",
                    decoration: BoxDecoration(
                      color: Color(0xF0FF0054),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  child: ListView.builder(
                    shrinkWrap : true,
                    physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: EdgeInsets.only(top:0),
                    itemCount: Provider.of<UserData>(context, listen: false).friendMap_list.length+1,
                    itemExtent: 80,
                    scrollDirection: Axis.vertical,
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                        width: size.width,
                        child: GestureDetector(
                          onTap: () {
                            var fmL = Provider.of<UserData>(context, listen: false).friendMap_list;

                            print ("index: $index");
                            if (fmL.length == index) {
                              print('helow');
                              Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) =>
                                    Search()
                                  )
                              );
                              return;
                            }

                            print('going to ${fmL[index]}');
                            String roomId = chatRoomId(_auth.currentUser?.uid, fmL[index]['uid']);
                            Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) =>
                                    ChatRoom(
                                      chatroomId: roomId,
                                      userMap: fmL[index],
                                    )
                                )
                            );
                          },
                          child: Provider.of<UserData>(context, listen: false).friendMap_list.length == index? addFriendCard() : Card(
                            margin: EdgeInsets.only(top: 2, bottom: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            color: Colors.white,
                            shadowColor: Colors.transparent,
                            child: Row(
                              children: [
                                SizedBox(width: 10),
                                Container(
                                    width: 63,
                                    height: 63,
                                    child: Avataaar(
                                      Is:Provider.of<UserData>(context, listen: false).friendMap_list[index]['avatarIs'] ?? [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                                      radius: 63,
                                      backgroundColor: Colors.transparent,
                                      mood: Provider.of<UserData>(context, listen: false).friendMap_list[index]['emotion'],
                                    )
                                ),
                                SizedBox(width: 20),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        width: size.width,
                                        child: Padding(
                                          padding: const EdgeInsets.only(left:5.0),
                                          child: Text(
                                            Provider.of<UserData>(context, listen: false).friendMap_list[index]['name'],
                                            style: TextStyle(
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        width: size.width,
                                        child: Center(
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Row(
                                              children: [
                                                Card(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(20.0),
                                                  ),

                                                  color: Color(0xf0f5f5f5),
                                                  shadowColor: Colors.transparent,
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(top:3.0, bottom: 3.0, right: 10.0, left: 10.0),
                                                    child: Text(
                                                        (Provider.of<UserData>(context, listen: false).friendMap_list[index]['emotion'] == 'Cherry'? '🍒'
                                                        : Provider.of<UserData>(context, listen: false).friendMap_list[index]['emotion'] == 'Lemonade'? '🍋'
                                                        : '☕') + ' '
                                                        + Provider.of<UserData>(context, listen: false).friendMap_list[index]['emotion'],
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: (emotionColor[Provider.of<UserData>(context, listen: false).friendMap_list[index]['emotion']])
                                                      )
                                                    ),
                                                  ),
                                                ),
                                                Card(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(20.0),
                                                  ),

                                                  color: Color(0xf0f5f5f5),
                                                  shadowColor: Colors.transparent,
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(top:3.0, bottom: 3.0, right: 10.0, left: 10.0),
                                                    child: StreamBuilder<DocumentSnapshot> (
                                                      stream: _firestore.collection('pingPointsChatroom').doc(chatRoomId(Provider.of<UserData>(context, listen: false).friendMap_list[index]['uid'] ,_auth.currentUser!.uid)).snapshots(),
                                                      builder: (context, snapshot) {
                                                        try {
                                                          return false? Container() : Text(
                                                            '👉 '
                                                            +snapshot
                                                              .data!['pingPoints']!.toString(),
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.black
                                                            )
                                                          );
                                                        } catch (e) {
                                                          print('error!: $e');
                                                          return Text(
                                                            '👉 '
                                                            + Provider.of<UserData>(context, listen: false).pingPoints[index].toString(),
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.black,
                                                            )
                                                          );
                                                        }
                                                      },
                                                    )
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                )
                              ]
                            )
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            )
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
                'Add a new mate',
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
                    child: Text(
                      '+',
                      style: TextStyle(
                        fontSize: 25,
                        color: Colors.white,
                      )
                    ),
                  ),
                )
              )
            ),
          ],
        )
    );
  }
}
