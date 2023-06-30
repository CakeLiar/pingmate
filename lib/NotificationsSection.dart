import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:work/providers/UserData.dart';

import 'avatar_scripts/Avataaar.dart';

class NotificationsSection extends StatefulWidget {

  List<Map<String, dynamic>> notifications = [];

  NotificationsSection({Key? key, required this.notifications}) : super(key: key);
  @override
  State<NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<NotificationsSection> {


  @override
  Widget build(BuildContext context) {
    print(widget.notifications);
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications")
      ),
      body: Container(
      width: size.width,
      child: widget.notifications.length == 0?
        Center (
          child: Text(
            'No recent notifications'
          )
        ) : ListView.builder(
        shrinkWrap : true,
        itemCount: widget.notifications.length,
        padding: EdgeInsets.only(top:0),
        physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        scrollDirection: Axis.vertical,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            width: size.width,
            height: 100,
            child: GestureDetector(
              onTap: () async {
                var theirUsermap = null;
                await FirebaseFirestore.instance.collection('users').doc(widget.notifications[index]['uid']).get().then((value){
                  theirUsermap = value.data();
                });
                if (theirUsermap == null) {
                  print('cannot add person');
                } else {
                  var _new = widget.notifications;

                  if (widget.notifications.length == 1)
                    _new = [];
                  else
                    _new.removeAt(index);


                  FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).set({
                    'notifications': _new,
                  }, SetOptions(merge: true)).then((_){
                    print('sat to $_new');
                  }).catchError((e){
                    print("couldn't $e");
                  });

                  setState((){
                    widget.notifications = _new;
                  });

                  Provider.of<UserData>(context, listen: false).addFriend(theirUsermap!);
                }
              },

              child: Card(
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
                              Is:widget.notifications[index]['avatarIs'] ?? [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                              radius: 63,
                              backgroundColor: Colors.transparent,
                              mood: widget.notifications[index]['emotion'] ?? 'Espresso',
                            )
                        ),
                        SizedBox(width: 10),
                        Expanded(

                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.notifications[index]['name'] + ' added you',
                                style: const TextStyle(
                                  fontSize: 13,
                                  overflow: TextOverflow.ellipsis,
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
                                      'Add'
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
    );
  }
}
