import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:work/HomeScreenbackup.dart';
import 'package:work/Me.dart';
import 'package:work/providers/NavBarController.dart';
import 'package:work/providers/NotificationController.dart';
import 'package:work/providers/UserData.dart';
import 'Methods.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'ChatRoom.dart';
import 'NewUpdate.dart';
import 'Search.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'Methods.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


Future<void> _backgroundHandler(RemoteMessage message) async {
  print ("Recieved background message");
  print(message.data['type']);

  Firebase.initializeApp();
  final _auth = FirebaseAuth.instance;

  print('authing');
  print(_auth);

  if(message.data['type'] == 'ping' || message.data['type'] == 'message') {

    var sender_name = message.data['sender-name'];
    var sender_uid = message.data['sender-uid'];

    print(message.data);

    NotificationController.createNewNotification (
        'PINGED', "$sender_name" + (message.data['type'] == 'ping'? " pinged you!" : " sent a message"), sender_name, sender_uid, chatRoomId(_auth.currentUser!.uid, sender_uid));

    Pinged();
  } else if (message.data['type'] == 'hold') {
    PingedLight();
  }

  /*
  FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();


  var notiDetails = NotificationDetails(android: AndroidNotificationDetails(
    'pingmate_channel',
    'channel_name',
    playSound: false,
    importance: Importance.max,
    priority: Priority.high,
    enableLights: true,
    actions: [
      AndroidNotificationAction('0', 'Ping')
    ],
  ));


  var androidInit = const AndroidInitializationSettings('@mipmap/ic_launcher');
  var initSettings = InitializationSettings(android: androidInit);

  await notificationsPlugin.initialize(
    initSettings,
    onDidReceiveBackgroundNotificationResponse: backgroundMessage2Noti,
    onDidReceiveNotificationResponse: backgroundMessage2Noti,
  );

  print ("initalized ^^");

  print(message.data);
  notificationsPlugin.show(0, 'Pinged', '${message.data['sender-name']} pinged you!', notiDetails, payload: message.data['sender-uid']);
   */
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {

  PersistentTabController _controller = PersistentTabController();
  FirebaseAnalytics firebaseAnalytics = FirebaseAnalytics.instance;

  final String appUpdateId = '123123123';


  void checkForUpdates() async {
    FirebaseFirestore _firestore = FirebaseFirestore.instance;

    _firestore.collection('updates').doc('final').get().then((value){
      try {
        if (value.data() != null){
          if (value.data()!['id'] != appUpdateId) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => NewUpdate(url: value.data()!['url']))
            );
          }
        }
      } catch (e){

      };
    });
  }

  @override
  void initState() {

    final FirebaseMessaging fm = FirebaseMessaging.instance;
    final FirebaseAuth _auth = FirebaseAuth.instance;

    checkForUpdates();

    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

    AwesomeNotifications().setListeners(
        onActionReceivedMethod: (ReceivedAction receivedAction) async {

      if(
      receivedAction.actionType == ActionType.SilentAction ||
          receivedAction.actionType == ActionType.SilentBackgroundAction
      ) {
      }
      else {
        Map<String, dynamic> sender_userMap = {};
        final _firestore = FirebaseFirestore.instance;

        print('GETTING USERR');
        await _firestore
            .collection('users')
            .doc(receivedAction.payload!['sender-uid'])
            .get().then((value) {
          Map<String, dynamic> data = value.data() as Map<String, dynamic>;
          sender_userMap = data;
          print('could firebase $sender_userMap');
        }).catchError((e){
          print('coudlnt firebase $e');
        });

        print('navigating');
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) =>
                ChatRoom(
                  chatroomId: receivedAction.payload!['chatroomId']!,
                  userMap: sender_userMap,
                  notAFriend: true,
                )
              //HomeScreenExtra()
            )
        ).then((_){
          print('naviagted? $_');
        }).catchError((e) {
          print('coudlnt navigate: $e');
        });
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {

      FirebaseAuth _auth = FirebaseAuth.instance;
      FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

      print ("Got message in background");

      if (message.data['type'] == 'ping' || message.data['type'] == 'message') {

        var sender_name = message.data['sender-name'];
        var sender_uid = message.data['sender-uid'];
        Map<String, dynamic> sender_userMap = {};

        print('GETTING USER');
        await firebaseFirestore
            .collection('users')
            .doc(sender_uid)
            .get().then((value) {
          Map<String, dynamic> data = value.data() as Map<String, dynamic>;
          sender_userMap = data;
        });

        if (sender_userMap == {}) {
          print("ERROR: usermap null, cannot open snackbar");
        }

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
      }
    });

    super.initState();

    WidgetsBinding.instance.addObserver(this);

    Provider.of<UserData>(context, listen: false).getLocalData();
    updateStatus(true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('hellowing');
    if (state == AppLifecycleState.resumed) {
      /// Online
      updateStatus(true);
    } else {
      /// Offline
      updateStatus(false);
    }
  }

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;

    final TextEditingController _search = TextEditingController();


    return PersistentTabView (
      context,
      navBarHeight: 90,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      confineInSafeArea: true,
      hideNavigationBar:  !Provider.of<NavBarController>(context).navBarShown,
      backgroundColor: Colors.black, // Default is Colors.white.
      handleAndroidBackButtonPress: true, // Default is true.
      resizeToAvoidBottomInset: false, // This needs to be true if you want to move up the screen when keyboard appears. Default is true.
      stateManagement: true, // Default is true.
      hideNavigationBarWhenKeyboardShows: true, // Recommended to set 'resizeToAvoidBottomInset' as true while using this argument. Default is true.
      decoration: const NavBarDecoration(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(10),
          topLeft: Radius.circular(10),
          bottomRight: Radius.circular(0),
          bottomLeft: Radius.circular(0),
        ),
        colorBehindNavBar: Colors.white,
      ),
      popAllScreensOnTapOfSelectedTab: true,
      popActionScreens: PopActionScreensType.all,
      itemAnimationProperties: const ItemAnimationProperties( // Navigation Bar's items animation properties.
        duration: Duration(milliseconds: 200),
        curve: Curves.ease,
      ),
      screenTransitionAnimation: const ScreenTransitionAnimation( // Screen transition animation on change of selected tab.
        animateTabTransition: false,
        curve: Curves.easeInOutCubicEmphasized,
        duration: Duration(milliseconds: 500),
      ),
      navBarStyle: NavBarStyle.neumorphic, // Choose the nav bar style with this property.
    );
  }

  List<Widget> _buildScreens() {
    return [
      HomeScreenExtra(),
      Me(),
      Search()
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(

        icon: Padding(
          padding: EdgeInsets.only(bottom: 30.0),
          child: Icon(CupertinoIcons.heart_circle),
        ),
        title: ("Mates"),
        activeColorPrimary: Color(0xF0FF0054),
        inactiveColorPrimary: CupertinoColors.systemGrey,
      ),
      PersistentBottomNavBarItem(
        icon: Padding(
          padding: EdgeInsets.only(bottom: 30.0),
          child: Icon(CupertinoIcons.person_circle_fill),
        ),
        title: ("Me"),
        activeColorPrimary: CupertinoColors.white,
        inactiveColorPrimary: CupertinoColors.systemGrey,
      ),
      PersistentBottomNavBarItem(
        icon: Padding(
          padding: EdgeInsets.only(bottom: 30.0),
          child: Icon(CupertinoIcons.add_circled_solid),
        ),
        title: ("Search"),
        activeColorPrimary: CupertinoColors.white,
        inactiveColorPrimary: CupertinoColors.systemGrey,
      ),
    ];
  }
}
