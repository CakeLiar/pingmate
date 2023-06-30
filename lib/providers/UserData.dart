import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Methods.dart';
import 'dart:convert';

class UserData extends ChangeNotifier {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  List<dynamic> friend_list = [];
  List<Map<String, dynamic>> friendMap_list = [];
  List<int> pingPoints = [];

  String currentScreen = 'Home';

  void updateCurrentScreen (String x) {
    currentScreen = x;
  }

  Future<void> getLocalData() async {
    print('getting local data');
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    try {
      if (_prefs.containsKey(_auth.currentUser!.uid)) {
        String? data = await _prefs.getString('${_auth.currentUser!.uid}');
        print('there should be data');
        print(data);
        Map<String, dynamic> mp = json.decode(data!);

        if (mp['friend_list'] != [])
          friend_list = mp['friend_list'];

        List<Map<String, dynamic>> maps = [];

        mp['friendMap_list'].forEach((_) {
          print(_);
          maps.add(_);
        });

        if (maps != []) {
          friendMap_list = maps;
        }

        List<int> points = [];
        mp['pingPoints'].forEach( (_) => points.add(_) );

        pingPoints = points;

        print(mp);
      } else {
        print('coudlnt');
      }
    } catch (e) {
      print('error!! ${e.toString()}');
      e.printError();
    }

    //notifyListeners();
  }

  Future<void> _saveLocalData() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    _prefs.setString('${_auth.currentUser!.uid}', json.encode({
      'friend_list': friend_list,
      'friendMap_list': friendMap_list,
      'pingPoints': pingPoints,
    }));
  }

  Future<bool> checkFriend(String uid) async {

    final _firestore = FirebaseFirestore.instance;

    await _firestore.collection('users').doc(uid).get().then((value){
      if (value.data() != null) {
        if (value.data()!['friend_list'].contains(_auth.currentUser!.uid)) {
          return true;
        } else {
          return false;
        }
      }
    }).catchError((e) {
      print('couldnt check friend');
      return false;
    });
    return false;
  }

  Future<void> addFriend (Map<String, dynamic> userMap, {bool noNoti = false}) async {

    sendAddFriendEvent(friend_list.length);

    friend_list.add(userMap['uid']);
    friendMap_list.add(userMap);

    Map<String, dynamic>? myusermap;

    print('hi hi hi ih');

    await firebaseFirestore.collection('users').doc(_auth.currentUser!.uid).get().then((value){
      if (value == null)
        print('error: what?');
      myusermap = value.data()!;

      var nw = DateTime.now();

      print('hihihi');
      print(myusermap!['friend_list']);
      print(userMap['uid']);
      if (!myusermap!['friend_list'].contains(userMap['uid'])) {
        addNotification(userMap['uid'], {
          'date': nw.year.toString() + nw.month.toString() + nw.day.toString() +
              nw.hour.toString() + nw.minute.toString() + nw.second.toString() +
              nw.millisecond.toString(),
          'uid': _auth.currentUser!.uid,
          'name': _auth.currentUser!.displayName,
          'avatarIs': myusermap!['avatarIs'] ??
              [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
          'emotion': myusermap!['emotion'],
          'command': 'add_friend'
        });
      }
    }).catchError((e){
      print('what the heck');
    });

    await firebaseFirestore.collection('users').doc(_auth.currentUser!.uid).set({
      'friend_list': FieldValue.arrayUnion([userMap["uid"]])
    }, SetOptions(merge: true));

    _saveLocalData();
    notifyListeners();
  }


  bool isGettingFriends = false;

  Future<void> getFriends () async {

    isGettingFriends = true;

    List<Map<String, dynamic>> tempFriendMapList = [];
    List<int> tempPoints = [];

    print("getFriends");
    await firebaseFirestore.collection('users').doc(_auth.currentUser?.uid).get().then((value){
      if (value.exists) {
        Map<String, dynamic>mp = value.data() as Map<String, dynamic>;
        friend_list = mp['friend_list'];
      }
    });
    for (int i = 0;i < friend_list.length; i++) {
      await firebaseFirestore
          .collection('users')
          .doc(friend_list[i])
          .get().then((value) {
        print("progress$i");
        Map<String, dynamic> data = value.data() as Map<String, dynamic>;
        tempFriendMapList.add(data);
      });

      await firebaseFirestore.collection('pingPointsChatroom').doc(chatRoomId(tempFriendMapList[i]['uid'] ,_auth.currentUser!.uid)).get().then((value){
        print('hi');

        print(value.data());
        if (value.data() == null)
          tempPoints.add(0);
        else if (!value.data()!.isEmpty)
          tempPoints.add(value.data()!['pingPoints']);
        else
          tempPoints.add(0);
      });
    }

    pingPoints = tempPoints;
    friendMap_list = tempFriendMapList;

    isGettingFriends = false;
    _saveLocalData();
    notifyListeners();
  }
}