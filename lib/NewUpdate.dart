import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class NewUpdate extends StatefulWidget {

  final String url;

  const NewUpdate({Key? key, required this.url}) : super(key: key);

  @override
  State<NewUpdate> createState() => _NewUpdateState();
}

class _NewUpdateState extends State<NewUpdate> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFF0B6E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'NEW UPDATE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 50,
                fontWeight: FontWeight.bold
              ),
            ),
            ElevatedButton(
              onPressed: () {
                launchUrlString(widget.url);
              },
              child: Text(
                'Update',
                style: TextStyle(
                  color: Color(0xFFFF0B6E),
                )
              ),
              style: ElevatedButton.styleFrom(
                shadowColor: Colors.transparent,
                elevation: 0,
                backgroundColor: Colors.white,
              )
            )
          ],
        ),
      )
    );
  }
}
