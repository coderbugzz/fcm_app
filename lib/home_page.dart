// lib/home_page.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _deviceToken;
  AuthorizationStatus? _authorizationStatus;

  Future<void> _getDeviceToken() async {
    final messaging = FirebaseMessaging.instance;

    String? token = await messaging.getToken();

    // do not proceed if context is not mounted
    // this disables the message do not use context
    // between async gaps
    if (!context.mounted) return;

    if (token != null) {
      // set the deviceToken
      setState(() {
        _deviceToken = token;
      });

      // copy to clipboard and notify user
      await Clipboard.setData(ClipboardData(text: token)).then((_) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully copied device token to clipboard'))));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to retrieve device token. Something went wrong')));
    }
  }

  Future<void> _requestPermission() async {
    final messaging = FirebaseMessaging.instance;

    // you can add more permissions as needed
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    setState(() {
      _authorizationStatus = settings.authorizationStatus;
    });
  }
  
  // this function will listen to incoming remote messages
  Future<void> _handleRemoteMessages() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        if (context.mounted) {
          final title = message.notification!.title;
          final body = message.notification!.body;

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title\n$body')));
        }
      }
    });
  }
  
  @override
  void initState() {
    _handleRemoteMessages();
    
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FCM Integration'),),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            // retrieve device token
            _deviceToken != null
              ? OutlinedButton(onPressed: _getDeviceToken, child: const Text('COPY DEVICE TOKEN'),)
              : FilledButton(onPressed: _getDeviceToken, child: const Text('GET DEVICE TOKEN'),),

            const SizedBox(height: 100),
            // request permission
            _authorizationStatus != null
              ? OutlinedButton(onPressed: _requestPermission, child:  Text(_authorizationStatus!.toLabel()),)
              : FilledButton(onPressed: _requestPermission, child: const Text('REQUEST PERMISSION'))
          ],),
        ],
      ),
    );
  }
}

// nice little helper to make authorization status human-friendly
extension ToLabel on AuthorizationStatus {
  String toLabel() {
    switch (this) {
      case AuthorizationStatus.denied:
        return 'NOTIFICATION PERMISSION DENIED';
      case AuthorizationStatus.authorized:
        return 'NOTIFICATION PERMISSION AUTHORIZED';
      case AuthorizationStatus.notDetermined:
        return 'NOTIFICATION PERMISSION UNKNOWN';
      case AuthorizationStatus.provisional:
        return 'NOTIFICATION PERMISSION PROVISIONAL';
    }
  }
}