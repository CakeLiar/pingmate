/*import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _notificationService =
  NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  static AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
    'channel id',
    'channel name',
    'channel description', //here shows the error
    importance: Importance.max,
  );


  static NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);


  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    final AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('app_icon');


    final InitializationSettings initializationSettings =
    InitializationSettings(
        android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: selectNotification);
  }


  Future<void> selectNotification(String? payload) async {
    if (payload == null) {
    } else {
      print (payload);
    }
  }

  Future<void> showNoti() async {

    await flutterLocalNotificationsPlugin.show(
        4,
        "hi",
        "thanks",
        platformChannelSpecifics,
        payload: "{Payload}");
  }
}*/