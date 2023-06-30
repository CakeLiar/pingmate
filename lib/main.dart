import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:work/Authenticate.dart';
import 'package:work/Me.dart';
import 'package:work/providers/NavBarController.dart';
import 'package:work/providers/NotificationController.dart';
import 'package:work/providers/UserData.dart';
import 'LoginScreen.dart';
import 'TestAvatar.dart';
import 'package:google_fonts/google_fonts.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationController.initializeLocalNotifications();
  await Firebase.initializeApp();

  print("booted");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
  FirebaseAnalyticsObserver(analytics: analytics);


  @override
  Widget build(BuildContext context) {
    print("Began");
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: NavBarController()
        ),
        ChangeNotifierProvider.value(
          value: UserData()
        ),
        ChangeNotifierProvider.value(
          value: NotificationController()
        )
      ],
      child: MaterialApp(
        theme: ThemeData(
          textTheme: GoogleFonts.poppinsTextTheme(),
          primarySwatch: Colors.grey,
          scaffoldBackgroundColor: Color(0xFFEEEEEE),
          appBarTheme: AppBarTheme(
            centerTitle: true,
            textTheme: GoogleFonts.poppinsTextTheme(),
            titleTextStyle: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
            foregroundColor: Colors.black,
            backgroundColor: Color(0xFFEEEEEE),
            shadowColor: Colors.transparent,
            systemOverlayStyle: SystemUiOverlayStyle(
              // Status bar color
              statusBarColor: Colors.transparent,

              // Status bar brightness (optional)
              statusBarIconBrightness: Brightness.dark, // For Android (dark icons)
              statusBarBrightness: Brightness.light, // For iOS (dark icons)
            ),
          )
        ),
        navigatorObservers: <NavigatorObserver>[observer],
        debugShowCheckedModeBanner: false,
        home: Authenticate(),
      ),
    );
  }
}