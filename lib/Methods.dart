import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'package:work/LoginScreen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:work/LoginScreen.dart' as ls;
import 'package:work/providers/UserData.dart';

List<String>topTypes = ["NoHair", "LongHairBigHair", "LongHairBob", "LongHairStraight", "LongHairFro", "LongHairCurvy", "LongHairStraightStrand",
  "ShortHairShaggyMullet", "ShortHairDreads02", "ShortHairShortCurly", "ShortHairShortFlat","ShortHairDreads01", "ShortHairTheCaesar"];
List<String>hairColors = ["Black", "Blonde", "Auburn", "PastelPink", "SliverGray", "Platinum", "Red"];
List<String>accessoriesTypes=["Blank", "Prescription01", "Round", "Sunglasses", "Kurt"];
List<String>facialHairTypes=["Blank", "BeardLight", "BeardMedium",  "MoustacheFancy"];
List<String>clotheTypes=["BlazerSweater", "CollarSweater", "ShirtVNeck", "GraphicShirt", "Hoodie", "Overall", "ShirtCrewNeck"];
List<String>clotheColors=["Black", "Heather", "White", "Pink", "PastelYellow", "Blue03", "Red"];
List<String>skinColors=["Tanned", "Light", "Brown", "DarkBrown", "Black", "Yellow", "Pale"];

Future<void> setUserProperty(String name, String value) async {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final FirebaseAnalyticsObserver observer =
    FirebaseAnalyticsObserver(analytics: analytics);
  await analytics.setUserProperty(name: name, value: value);
  print('setUserProperty succeeded');
}

Future<void> setCurrentScreen(String screenName) async {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final FirebaseAnalyticsObserver observer =
    FirebaseAnalyticsObserver(analytics: analytics);

  await analytics.setCurrentScreen(
    screenName: screenName,
    screenClassOverride: screenName,
  );
  print('setCurrentScreen succeeded');
}

Future<void> sendPingCatEvent(String from) async {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final FirebaseAnalyticsObserver observer =
  FirebaseAnalyticsObserver(analytics: analytics);

  var now = DateTime.now();
  await analytics.logEvent(
    name: 'Ping Cat',
    parameters: <String, dynamic>{
      'from': from,
      'time': DateTime(now.year, now.month, now.day, now.hour, now.minute).toString(),
      // Only strings and numbers (ints & doubles) are supported for GA custom event parameters:
      // https://developers.google.com/analytics/devguides/collection/analyticsjs/custom-dims-mets#overview
    },
  );
  print("Sent Ping Cat Event");
}

Future<void> sendPingEvent(String from, String to) async {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final FirebaseAnalyticsObserver observer =
    FirebaseAnalyticsObserver(analytics: analytics);

  var now = DateTime.now();
  await analytics.logEvent(
    name: 'Ping',
    parameters: <String, dynamic>{
      'from': from,
      'to': to,
      'time': DateTime(now.year, now.month, now.day, now.hour, now.minute).toString(),
      // Only strings and numbers (ints & doubles) are supported for GA custom event parameters:
      // https://developers.google.com/analytics/devguides/collection/analyticsjs/custom-dims-mets#overview
    },
  );
  print("Sent Ping Event");
}

Future<void> sendEvent(String eventName) async {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final FirebaseAnalyticsObserver observer =
  FirebaseAnalyticsObserver(analytics: analytics);

  var now = DateTime.now();
  await analytics.logEvent(
    name: eventName,
    parameters: <String, dynamic>{
      'time': DateTime(now.year, now.month, now.day, now.hour, now.minute).toString(),
      },
  );
  print("Sent Custom Event");
}

Future<void> sendSearchEvent(String searchText, int friendCount) async {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final FirebaseAnalyticsObserver observer =
  FirebaseAnalyticsObserver(analytics: analytics);

  var now = DateTime.now();
  await analytics.logEvent(
    name: "Search",
    parameters: <String, dynamic>{
      "searchText": searchText,
      "friendCount": friendCount,
      'time': DateTime(now.year, now.month, now.day, now.hour, now.minute).toString(),
    },
  );
  print("Sent Ping Event");
}

Future<void> addNotification (String uid, Map<String, dynamic> notification) async {

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  print('sending notifications');

  await _firestore.collection('users').doc(uid).set({
    'notifications': FieldValue.arrayUnion([notification])
  }, SetOptions(merge: true)).then((_){
    print('okay?');
  }).catchError((e) {
    print('coldn"t: $e');
  });
}


Future<void> sendAddFriendEvent(int friendCount) async {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final FirebaseAnalyticsObserver observer =
  FirebaseAnalyticsObserver(analytics: analytics);

  var now = DateTime.now();
  await analytics.logEvent(
    name: "AddFriend",
    parameters: <String, dynamic>{
      "friendCount": friendCount,
      'time': DateTime(now.year, now.month, now.day, now.hour, now.minute).toString(),
    },
  );
  print("Sent Ping Event");
}

Future<void> updateWatchingChatroom(String chatroomId, bool online) async {
  print('updating status');
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  print(online);
  await _firestore.collection('chatrooms').doc(chatroomId).set({
    _auth.currentUser!.uid:  online
  }, SetOptions(merge:true)).catchError((e){
    print('ERROR SETTING STATUS: $e');
  });
}

Future<void> updateStatus(bool online) async {
  print('updating status');
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  print(online);

  await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
    'status': online
  }, SetOptions(merge: true)).catchError((e){
    print('ERROR SETTING STATUS: $e');
  });
}

Future<int> getPingPoints (String chatroomId) async {
  var _firestore = FirebaseFirestore.instance;
  int pings = 0;
  await _firestore.collection('pingPointsChatroom').doc(chatroomId).get().then((value){
    try {
      if (value.data()?['pingPoints'] == null) {
        updatePingPoints(chatroomId, 0);
        return 0;
      }
    } catch(e) {
      updatePingPoints(chatroomId, 0);
    }
    pings = value.data()!['pingPoints'];
  }).catchError((e){
    print('error couldn\'nt get ping points');
    return 0;
  });
  return pings;
}

Future<void> updatePingPoints(String chatroomId, int value) async {
  var _firestore = FirebaseFirestore.instance;
  await _firestore.collection('pingPointsChatroom').doc(chatroomId).set({
    'pingPoints': value,
  }, SetOptions(merge: true)).catchError((e){
    print('ERROR UPDATING $e');
  });
}

String chatRoomId(String ?user1, String ?user2) {
  var user1Str = user1!;
  var user2Str = user2!;
  print("creating chatroomid, user1: $user1Str, user2: $user2Str");
  for (int i = 0; i < min(user1.length, user2.length); i++) {
    if (user1Str.codeUnits[i] == user2Str.codeUnits[i])
      continue;
    else if (user1Str.codeUnits[i] > user2Str.codeUnits[i])
      return "$user1Str$user2Str";
    else
      return "$user2Str$user1Str";
  }
  return "$user1Str$user2Str";
}

Future<void> sendHoldNotification(token ) async {

  print('token : $token');

  var myname = FirebaseAuth.instance.currentUser?.displayName;
  var myuid = FirebaseAuth.instance.currentUser?.uid;

  final data = {
    "priority": "high",
    "data": {
      "type": "hold",
      "click_action": "FLUTTER_NOTIFICATION_CLICK",
      "sender-name": myname,
      "sender-uid": myuid,
      "receiver": token
    },
    "from": myname,
    "to": "$token"
  };

  final headers = {
    'content-type': 'application/json',
    'Authorization': 'key=AAAA0ii94oc:APA91bG0N1et7K421QBari0mw9lwJWdPxU5Gz1TLwC-Rf95bCdxNTC1VqmM2--_-6oFL_hB9ee8BtDINexrWH_Qau_Yrc3vNgT-3QJjKq2v8AK4s1kV5pCE_QkZ-Q82379qm6S7i8Z_U'
  };


  BaseOptions options = new BaseOptions(
    connectTimeout: 5000,
    receiveTimeout: 3000,
    headers: headers,
  );

  var postUrl = "https://fcm.googleapis.com/fcm/send";
  Future.delayed(Duration(seconds:0), () async {
    try {
      final response = await Dio(options).post(postUrl,
          data: data);

      if (response.statusCode == 200) {
        print('held');
      } else {
        print('couldn\'t cold');
      }
    }
    catch(e){
      print('exception $e');
    }
  });
}

void updateLocalCurrentScreen (BuildContext context, String x) {
  Provider.of<UserData>(context, listen: false).updateCurrentScreen(x);
}

String getLocalCurrentScreen (BuildContext context) {
  return Provider.of<UserData>(context, listen: false).currentScreen;
}

Future<void> sendPingNotification(token ) async {

  print('token : $token');

  var myname = FirebaseAuth.instance.currentUser?.displayName;
  var myuid = FirebaseAuth.instance.currentUser?.uid;

  final data = {
    "priority": "high",
    "data": {
      "type": "ping",
      "click_action": "FLUTTER_NOTIFICATION_CLICK",
      "sender-name": myname,
      "sender-uid": myuid,
      "receiver": token
    },
    "from": myname,
    "to": "$token"
  };

  final headers = {
    'content-type': 'application/json',
    'Authorization': 'key=AAAA0ii94oc:APA91bG0N1et7K421QBari0mw9lwJWdPxU5Gz1TLwC-Rf95bCdxNTC1VqmM2--_-6oFL_hB9ee8BtDINexrWH_Qau_Yrc3vNgT-3QJjKq2v8AK4s1kV5pCE_QkZ-Q82379qm6S7i8Z_U'
  };


  BaseOptions options = new BaseOptions(
    connectTimeout: 5000,
    receiveTimeout: 3000,
    headers: headers,
  );

  var postUrl = "https://fcm.googleapis.com/fcm/send";

  Future.delayed(Duration(seconds:0), () async {
    try {
      final response = await Dio(options).post(postUrl,
          data: data);
    }
    catch(e){
      Fluttertoast.showToast(msg: 'Check your internet!');
    }
  });
}

Future<void> sendMessageNotification(token, message) async {

  var myname = FirebaseAuth.instance.currentUser?.displayName;
  var myuid = FirebaseAuth.instance.currentUser?.uid;

  final data = {
    "priority": "high",
    "data": {
      "type": "message",
      "click_action_uid": "FLUTTER_NOTIFICATION_CLICK",
      "sender-name": myname,
      "sender-uid": myuid,
      "reciever": token
    },

    "from": myname,
    "to": "$token"
  };

  final headers = {
    'content-type': 'application/json',
    'Authorization': 'key=AAAA0ii94oc:APA91bG0N1et7K421QBari0mw9lwJWdPxU5Gz1TLwC-Rf95bCdxNTC1VqmM2--_-6oFL_hB9ee8BtDINexrWH_Qau_Yrc3vNgT-3QJjKq2v8AK4s1kV5pCE_QkZ-Q82379qm6S7i8Z_U'
  };


  BaseOptions options = new BaseOptions(
    connectTimeout: 5000,
    receiveTimeout: 3000,
    headers: headers,
  );

  var postUrl = "https://fcm.googleapis.com/fcm/send";

  try {
    final response = await Dio(options).post(postUrl,
        data: data);

    if (response.statusCode == 200) {
    } else {
      Fluttertoast.showToast(msg: 'Check your internet');
    }
  }
  catch(e){
    print('exception $e');
  }
}

Future<bool> saveAvatar(List<int> avatarArray, String emotionalState) async {
  FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;
  print("saving $emotionalState");

  if (emotionalState == '-1' && avatarArray.isEmpty) {
    print ("error, function saveAvatar called with no parameters");
    return false;
  }

  if (emotionalState == '-1') {
    await firebaseFirestore.collection('users').doc(_auth.currentUser?.uid).set(
        {
          'avatarIs': avatarArray,
        }, SetOptions(merge: true)
    ).catchError((onError){
      return false;
    });
  } else {
    await firebaseFirestore.collection('users').doc(_auth.currentUser?.uid).set(
        {
          'avatarIs': avatarArray,
          'emotion': emotionalState,
        }, SetOptions(merge: true)
    ).catchError((onError) {
      return false;
    });
  }

  setUserProperty('mood', emotionalState);
  setUserProperty('hair', topTypes[avatarArray[0]]);
  setUserProperty('clothes', topTypes[avatarArray[0]]);

  print("saved");

  return true;
}



Future<List<int>> getAvatarIs(User? user) async {
  FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;

  var avatarFeatures = [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1];
  print("getting avatar");
  await firebaseFirestore.collection('users').doc(user?.uid).get().then((value) async {
    print("hiii");
    print(value.data());
    Map<String, dynamic>mp = value.data() as Map<String, dynamic>;
    //avatarFeatures = mp['avatar'] as List<int>;
    print("done");
    try {
      for (int i = 0; i < mp['avatarIs'].length; i++)
        avatarFeatures[i] = mp['avatarIs'][i];
    } catch (e) {
      await saveAvatar([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], '-1');
      avatarFeatures = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ,0];
    }
    print (avatarFeatures);
  });
  return avatarFeatures;
}

void Pinged () {
  Vibration.vibrate(pattern:[50, 25, 50, 25, 50, 25, 50, 25]);
}

void PingedLight () {
  Vibration.vibrate(pattern:[0, 1, 0, 5]);
}

///Inside function
String getAvatarUrlFromArray (List<int> avatarFeatures, String emotionalState) {

  print("SHOULDN'T BE USING THIS");
  String topType = topTypes[avatarFeatures[0]%topTypes.length];
  String hairColor = hairColors[avatarFeatures[1]%hairColors.length];
  String accessoriesType = accessoriesTypes[avatarFeatures[2]%accessoriesTypes.length];
  String facialHairType = facialHairTypes[avatarFeatures[3]%facialHairTypes.length];
  String clotheType = clotheTypes[avatarFeatures[4]%clotheTypes.length];
  String clotheColor = clotheColors[avatarFeatures[5]%clotheColors.length];
  String skinColor = skinColors[avatarFeatures[6]%skinColors.length];

  String eyeType="Default", eyebrowType = "Default", mouthType = "Default";

  print ("emotionalState");
  print (emotionalState);

  switch (emotionalState) {
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

  print ("https://avataaars.io/?clotheColor=$clotheColor&avatarStyle=Circle&topType=$topType&accessoriesType=$accessoriesType&hairColor=$hairColor&facialHairType=$facialHairType&clotheType=$clotheType&eyeType=$eyeType&eyebrowType=$eyebrowType&mouthType=$mouthType&skinColor=$skinColor");

  return "https://avataaars.io/?clotheColor=$clotheColor&avatarStyle=Circle&topType=$topType&accessoriesType=$accessoriesType&hairColor=$hairColor&facialHairType=$facialHairType&clotheType=$clotheType&eyeType=$eyeType&eyebrowType=$eyebrowType&mouthType=$mouthType&skinColor=$skinColor";
}



Future<User?> signInWithGoogle ({BuildContext? context = null}) async {
  GoogleSignInAccount? _user;
  final googleSignIn = GoogleSignIn(scopes: ['profile', 'email']);
  final _auth = FirebaseAuth.instance;

  final googleUser = await googleSignIn.signIn();
  final _firestore = FirebaseFirestore.instance;

  final googleAuth = await googleUser!.authentication;

  if (googleUser == null)
    return null;

  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  User? user = (await _auth.signInWithCredential(credential)).user;

  String? name = null;


  try {
    await _firestore.collection('users').doc(_auth.currentUser?.uid)
        .get()
        .then((value) {
      if (value.exists) {
        Map<String, dynamic>mp = value.data() as Map<String, dynamic>;
        name = mp['name']??null;
      }
    });
  } catch (e) {
    print('finally: something wrong');
    e.printError();
    print(e);
  }

  if (name == null) {
    print("Created");
    await _firestore.collection('users').doc(_auth.currentUser?.uid).set({
      "name": googleUser.displayName,
      "nameS": googleUser.displayName.toString().toLowerCase().replaceAll(" ", ""),
      "email": googleUser.email.replaceAll(" ", ""),
      "status": false,
      "token": "",
      "friend_list": [],
      "uid": _auth.currentUser?.uid,
      "avatarIs": [0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0],
      "emotion": "Cherry"
    }, SetOptions(merge: true));

  } else {
    print("Existing User: " + name!);
  }
  return user;
}

Future<User?> login (String email, String password) async {
  FirebaseAuth _auth = FirebaseAuth.instance;
  try {
    User user = (await _auth.signInWithEmailAndPassword(
        email: email, password: password))
        .user!;
    if (user != null) {
      print ("Login Successful");
      return user;
    } else {
      print("Login failed");
      return user;
    }
  } catch (e) {
    print (e);
    return null;
  }
}

Future logout (BuildContext context) async {
  FirebaseAuth _auth = FirebaseAuth.instance;
  try {
    await _auth.signOut().then((value){
      Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen()));
    });
  } catch (e) {
    print ("Error!!11!");
  }
}

